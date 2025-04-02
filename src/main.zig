//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const Style = @import("Utils/style.zig").Style; // if in a separate file

pub fn printHelp() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{s}usage:{s} {s}{s}zigterp{s} [option] ... [-c cmd | -m mod | file | -] [arg] ...\n\n", .{ Style.heading, Style.reset, Style.fg_magenta, Style.underline, Style.reset });

    try stdout.print("{s}Options:{s}\n", .{ Style.heading, Style.reset });
    try stdout.print("  {s}-h{s}, {s}--help{s}: print this help menu\n\n", .{ Style.flag, Style.reset, Style.flag, Style.reset });

    try stdout.print("{s}Arguments:{s}\n", .{ Style.heading, Style.reset });
    try stdout.print("  {s}file{s}   : program read from script file\n", .{ Style.example, Style.reset });
    try stdout.print("  {s}-{s}      : program read from stdin (default; interactive if tty)\n", .{ Style.example, Style.reset });
    try stdout.print("  {s}arg ...{s}: arguments passed to program in sys.argv[1:]\n", .{ Style.example, Style.reset });

    try bw.flush();
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // Don't forget to flush!

    try printHelp();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "use other module" {
    try std.testing.expectEqual(@as(i32, 150), lib.add(100, 50));
}

test "fuzz example" {
    const global = struct {
        fn testOne(input: []const u8) anyerror!void {
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(global.testOne, .{});
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("zigterpreter_lib");
