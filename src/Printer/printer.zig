const std = @import("std");

const Style = @import("../Utils/style.zig");

pub const Printer = struct {
    bw: std.io.BufferedWriter(4096, std.fs.File.Writer),

    pub fn init() Printer {
        const writer = std.io.getStdOut().writer();
        return .{ .bw = std.io.bufferedWriter(writer) };
    }

    pub fn print(self: *Printer, comptime fmt: []const u8, args: anytype) !void {
        try self.bw.writer().print(fmt, args);
        try self.bw.flush(); // auto-flush after every print
    }

    pub fn printStyled(
        self: *Printer,
        style: []const u8,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        const writer = self.bw.writer();
        try writer.print("{s}", .{style});
        try writer.print(fmt, args);
        try writer.print("{s}", .{Style.Style.reset});
        try self.bw.flush();
    }

    pub fn printInfo(self: *Printer, comptime fmt: []const u8, args: anytype) !void {
        try self.printStyled(Style.Style.blue, fmt, args);
    }

    pub fn printError(self: *Printer, comptime fmt: []const u8, args: anytype) !void {
        try self.printStyled(Style.Style.error_style, fmt, args);
    }

    pub fn printResult(self: *Printer, comptime fmt: []const u8, args: anytype) !void {
        try self.printStyled(Style.Style.flag, fmt, args);
    }
};

//const std = @import("std");

pub const TerminalType = enum {
    unknown,
    kitty,
    wezterm,
    alacritty,
    iterm2,
    ghostty,
    vscode,
    windows_terminal,
    basic_ansi,
};

pub fn detectTerminal(env: std.process.EnvMap) TerminalType {
    if (env.get("KITTY_WINDOW_ID") != null) return .kitty;
    if (env.get("TERM_PROGRAM")) |prog| {
        if (std.mem.eql(u8, prog, "iTerm.app")) return .iterm2;
        if (std.mem.eql(u8, prog, "WezTerm")) return .wezterm;
        if (std.mem.eql(u8, prog, "Apple_Terminal")) return .basic_ansi;
    }
    if (env.get("WT_SESSION") != null) return .windows_terminal;
    if (env.get("ALACRITTY_SOCKET") != null) return .alacritty;
    if (env.get("TERM")) |term| {
        if (std.mem.containsAtLeast(u8, term, 1, "xterm")) return .basic_ansi;

        if (std.mem.containsAtLeast(u8, term, 1, "linux")) return .basic_ansi;
        if (std.mem.containsAtLeast(u8, term, 1, "screen")) return .basic_ansi;
    }

    if (env.get("COLORTERM")) |color| {
        if (std.mem.eql(u8, color, "truecolor") or std.mem.eql(u8, color, "24bit")) {
            // enable 24-bit color
        }
    }

    if (env.get("LC_CTYPE")) |ctype| {
        if (std.mem.containsAtLeast(u8, ctype, 1, "UTF-8")) {
            // enable Unicode symbols
        }
    }

    return .unknown;
}
