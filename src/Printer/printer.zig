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
