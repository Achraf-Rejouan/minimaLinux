#!/usr/bin/env python3
"""Minimal GTK4 popup for the ThinkPad battery charge limit.

The GUI is unprivileged. It reads sysfs directly for display and calls only
the root-owned helper in /usr/local/bin through pkexec for changes.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gio, GLib, Gtk, Pango

APP_ID = "org.minima.BatteryChargeLimit"
BATTERY = Path("/sys/class/power_supply/BAT0")
CONFIG = Path("/etc/battery-charge-limit.conf")
PKEXEC = "/usr/bin/pkexec"
HELPER = "/usr/local/bin/battery-charge-limit"

REFRESH_SECONDS = 3
DEFAULT_START = 85
DEFAULT_END = 90
FULL_START = 95
FULL_END = 100

WINDOW_WIDTH = 340
WINDOW_HEIGHT = 320


def read_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="ascii").strip()
    except (OSError, UnicodeError):
        return None


def read_int(path: Path) -> int | None:
    value = read_text(path)
    if value is None:
        return None
    try:
        return int(value)
    except ValueError:
        return None


def read_battery() -> tuple[int | None, str | None, int | None, int | None]:
    """Return capacity, status, start threshold, end threshold."""
    return (
        read_int(BATTERY / "capacity"),
        read_text(BATTERY / "status"),
        read_int(BATTERY / "charge_control_start_threshold"),
        read_int(BATTERY / "charge_control_end_threshold"),
    )


def read_config_limits() -> tuple[int, int]:
    """Read START/END from the root-owned config without executing it."""
    start = DEFAULT_START
    end = DEFAULT_END
    try:
        lines = CONFIG.read_text(encoding="ascii").splitlines()
    except (OSError, UnicodeError):
        return start, end

    for raw in lines:
        line = raw.strip()
        match = re.fullmatch(r"(START|END)=([0-9]+)", line)
        if not match:
            continue
        value = int(match.group(2))
        if match.group(1) == "START":
            start = value
        else:
            end = value

    if 0 <= start <= end <= 100:
        return start, end
    return DEFAULT_START, DEFAULT_END


def display_status(status: str | None) -> str:
    if not status:
        return "Unknown"
    return status


def threshold_mode(
    start: int | None,
    end: int | None,
    target_start: int,
    target_end: int,
) -> str:
    if start is None or end is None:
        return "unknown"
    if start == target_start and end == target_end:
        return "limit"
    if (start, end) == (FULL_START, FULL_END) and (
        target_start,
        target_end,
    ) != (FULL_START, FULL_END):
        return "full"
    return "custom"


def helper_problem() -> str | None:
    """Refuse to call anything but the root-owned helper."""
    if not os.access(PKEXEC, os.X_OK):
        return f"pkexec not found: {PKEXEC}"
    try:
        stat = os.stat(HELPER)
    except OSError:
        return f"Helper not installed: {HELPER}"
    if stat.st_uid != 0:
        return f"Helper is not owned by root: {HELPER}"
    if stat.st_mode & 0o022:
        return f"Helper is writable by non-root: {HELPER}"
    if not os.access(HELPER, os.X_OK):
        return f"Helper is not executable: {HELPER}"
    return None


def short_text(text: str, limit: int = 180) -> str:
    text = " ".join(text.split())
    if len(text) <= limit:
        return text
    return text[: limit - 1] + "…"


class BatteryWindow(Gtk.ApplicationWindow):
    def __init__(self, application: Gtk.Application) -> None:
        super().__init__(application=application, title="Battery Charge Limit")
        self.set_default_size(WINDOW_WIDTH, WINDOW_HEIGHT)
        self.set_resizable(False)

        self.target_start, self.target_end = read_config_limits()
        self.startup_problem = helper_problem()
        self.timeout_id = 0
        self.message_timeout_id = 0
        self.proc: Gio.Subprocess | None = None
        self.closed = False
        self.battery_ok = False

        self._build_ui()
        self.connect("close-request", self._on_close_request)
        self._update_status()
        self.timeout_id = GLib.timeout_add_seconds(
            REFRESH_SECONDS, self._on_timeout
        )

    def _build_ui(self) -> None:
        header = Gtk.HeaderBar()
        header.set_show_title_buttons(True)
        header.set_title_widget(Gtk.Label(label="Battery"))
        self.set_titlebar(header)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        outer.set_margin_top(16)
        outer.set_margin_bottom(16)
        outer.set_margin_start(16)
        outer.set_margin_end(16)
        self.set_child(outer)

        top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        top.set_valign(Gtk.Align.CENTER)
        self.percent_label = Gtk.Label(label="--%", xalign=0)
        self.percent_label.set_hexpand(True)
        self.state_label = Gtk.Label(label="Unknown", xalign=1)
        self.state_label.set_valign(Gtk.Align.END)
        self.state_label.add_css_class("dim-label")
        top.append(self.percent_label)
        top.append(self.state_label)
        outer.append(top)

        self.limit_label = Gtk.Label(xalign=0)
        self.limit_label.set_wrap(True)
        self.limit_label.set_wrap_mode(Pango.WrapMode.WORD_CHAR)
        self.limit_label.set_lines(2)
        self.limit_label.set_ellipsize(Pango.EllipsizeMode.END)
        outer.append(self.limit_label)

        self.notice_label = Gtk.Label(xalign=0)
        self.notice_label.set_wrap(True)
        self.notice_label.set_wrap_mode(Pango.WrapMode.WORD_CHAR)
        self.notice_label.set_lines(2)
        self.notice_label.set_ellipsize(Pango.EllipsizeMode.END)
        self.notice_label.add_css_class("dim-label")
        self.notice_label.set_visible(False)
        outer.append(self.notice_label)

        self.action_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.action_box.set_valign(Gtk.Align.CENTER)
        self.action_box.set_visible(False)
        self.spinner = Gtk.Spinner()
        self.action_label = Gtk.Label(xalign=0)
        self.action_label.add_css_class("dim-label")
        self.action_box.append(self.spinner)
        self.action_box.append(self.action_label)
        outer.append(self.action_box)

        self.message_label = Gtk.Label(xalign=0)
        self.message_label.set_wrap(True)
        self.message_label.set_wrap_mode(Pango.WrapMode.WORD_CHAR)
        self.message_label.set_lines(2)
        self.message_label.set_ellipsize(Pango.EllipsizeMode.END)
        self.message_label.set_visible(False)
        outer.append(self.message_label)

        self.limit_button = Gtk.Button()
        self.limit_button.set_hexpand(True)
        self.limit_button.connect("clicked", self._on_limit_clicked)
        outer.append(self.limit_button)

        self.full_button = Gtk.Button(label="Charge to 100% once")
        self.full_button.set_hexpand(True)
        self.full_button.set_tooltip_text(
            "Temporarily allow charging to 100%. "
            "Returns to the configured limit after the next reboot or sleep."
        )
        self.full_button.connect("clicked", self._on_full_clicked)
        outer.append(self.full_button)

        self._update_buttons("unknown")

    def _set_percent(self, capacity: int | None) -> None:
        if capacity is None:
            self.percent_label.set_markup(
                "<span size='xx-large' weight='bold'>--%</span>"
            )
        else:
            self.percent_label.set_markup(
                f"<span size='xx-large' weight='bold'>{capacity}%</span>"
            )

    def _update_buttons(self, mode: str) -> None:
        for button in (self.limit_button, self.full_button):
            button.remove_css_class("suggested-action")

        if mode == "full":
            self.limit_button.set_label(f"Back to {self.target_end}%")
            self.limit_button.set_tooltip_text(
                f"Return to the configured {self.target_end}% limit."
            )
            self.full_button.add_css_class("suggested-action")
        else:
            self.limit_button.set_label(
                f"Limit to {self.target_end}% (recommended)"
            )
            self.limit_button.set_tooltip_text(
                f"Apply the configured {self.target_start}/{self.target_end} limit."
            )
            if mode == "limit":
                self.limit_button.add_css_class("suggested-action")

        self._apply_sensitivity()

    def _update_status(self) -> None:
        capacity, status, start, end = read_battery()

        if capacity is None or start is None or end is None:
            self.battery_ok = False
            self._set_percent(None)
            self.state_label.set_text("Unavailable")
            self.limit_label.set_text("Could not read BAT0 status.")
            self.notice_label.set_visible(False)
            self._update_buttons("unknown")
            return

        self.battery_ok = True
        mode = threshold_mode(start, end, self.target_start, self.target_end)
        self._set_percent(capacity)
        self.state_label.set_text(display_status(status))
        self.limit_label.set_text(
            f"Limit: {end}% (charging resumes below {start}%)"
        )

        if mode == "full":
            self.notice_label.set_text(
                f"Temporary 100%: returns to {self.target_end}% "
                "after the next reboot or sleep."
            )
            self.notice_label.set_visible(True)
        elif mode == "custom":
            self.notice_label.set_text(
                f"Custom thresholds: {start}/{end}. "
                f"Configured limit: {self.target_start}/{self.target_end}."
            )
            self.notice_label.set_visible(True)
        else:
            self.notice_label.set_visible(False)

        self._update_buttons(mode)

    def _apply_sensitivity(self) -> None:
        enabled = (
            self.battery_ok
            and self.startup_problem is None
            and self.proc is None
        )
        self.limit_button.set_sensitive(enabled)
        self.full_button.set_sensitive(enabled)

    def _on_timeout(self) -> bool:
        if self.closed:
            return False
        self._update_status()
        return True

    def _cancel_message_timeout(self) -> None:
        if self.message_timeout_id:
            GLib.source_remove(self.message_timeout_id)
            self.message_timeout_id = 0

    def _clear_message(self) -> bool:
        self.message_timeout_id = 0
        self.message_label.set_text("")
        self.message_label.set_visible(False)
        return False

    def _show_message(self, text: str, timeout: int = 0) -> None:
        self._cancel_message_timeout()
        self.message_label.set_text(text)
        self.message_label.set_visible(True)
        if timeout:
            self.message_timeout_id = GLib.timeout_add_seconds(
                timeout, self._clear_message
            )

    def _show_error(self, text: str) -> None:
        self._show_message(f"Error: {short_text(text)}")

    def _set_busy(self, busy: bool, text: str = "") -> None:
        if busy:
            self.action_label.set_text(text)
            self.action_box.set_visible(True)
            self.spinner.start()
        else:
            self.spinner.stop()
            self.action_box.set_visible(False)
        self._apply_sensitivity()

    def _run_helper(self, mode: str) -> None:
        if self.proc is not None or self.closed:
            return
        if not self.battery_ok:
            self._show_error("Battery status is unavailable.")
            return
        if self.startup_problem is not None:
            self._show_error(self.startup_problem)
            return

        self._cancel_message_timeout()
        self.message_label.set_visible(False)
        self._set_busy(True, "Waiting for authentication…")

        try:
            proc = Gio.Subprocess.new(
                [PKEXEC, HELPER, mode],
                Gio.SubprocessFlags.STDOUT_PIPE
                | Gio.SubprocessFlags.STDERR_PIPE,
            )
        except GLib.Error as exc:
            self._set_busy(False)
            self._show_error(f"Could not start pkexec: {exc.message}")
            return

        self.proc = proc
        self._apply_sensitivity()
        proc.communicate_utf8_async(None, None, self._on_helper_done, mode)

    def _on_helper_done(
        self, proc: Gio.Subprocess, result: Gio.AsyncResult, mode: str
    ) -> None:
        if self.closed:
            return

        try:
            _ok, _stdout, stderr = proc.communicate_utf8_finish(result)
        except GLib.Error as exc:
            self.proc = None
            self._set_busy(False)
            self._show_error(f"pkexec failed: {exc.message}")
            return

        self.proc = None
        self._set_busy(False)

        if proc.get_if_exited():
            code = proc.get_exit_status()
        else:
            code = -1

        if code == 0:
            self._update_status()
            if mode == "full":
                message = "Temporary 100% enabled."
            else:
                message = "Limit applied."
            self._show_message(message, timeout=4)
            return

        if code == 126:
            self._show_error("Authentication cancelled.")
        elif code == 127:
            self._show_error("Not authorized.")
        elif code == 125:
            self._show_error("PolicyKit error.")
        else:
            detail = short_text(stderr or "")
            prefix = "battery-charge-limit: "
            if detail.startswith(prefix):
                detail = detail[len(prefix):]
            if detail:
                self._show_error(f"Helper failed: {detail}")
            else:
                self._show_error(f"Helper failed (exit {code}).")

    def _on_limit_clicked(self, _button: Gtk.Button) -> None:
        self._run_helper("limit")

    def _on_full_clicked(self, _button: Gtk.Button) -> None:
        self._run_helper("full")

    def shutdown(self) -> None:
        if self.closed:
            return
        self.closed = True
        if self.timeout_id:
            GLib.source_remove(self.timeout_id)
            self.timeout_id = 0
        self._cancel_message_timeout()
        if self.proc is not None:
            try:
                self.proc.force_exit()
            except GLib.Error:
                pass
            self.proc = None

    def _on_close_request(self, _window: Gtk.Window) -> bool:
        self.shutdown()
        return False


class BatteryApplication(Gtk.Application):
    def __init__(self) -> None:
        super().__init__(
            application_id=APP_ID,
            flags=Gio.ApplicationFlags.DEFAULT_FLAGS,
        )
        self.window: BatteryWindow | None = None

    def do_activate(self) -> None:
        if self.window is None:
            self.window = BatteryWindow(self)
            self.window.connect("destroy", self._on_window_destroyed)
        self.window.present()

    def _on_window_destroyed(self, _window: Gtk.Window) -> None:
        self.window = None

    def do_shutdown(self) -> None:
        if self.window is not None:
            self.window.shutdown()
        Gtk.Application.do_shutdown(self)


def main() -> int:
    GLib.set_prgname("battery-charge-limit-gui")
    GLib.set_application_name("Battery Charge Limit")
    app = BatteryApplication()
    return app.run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
