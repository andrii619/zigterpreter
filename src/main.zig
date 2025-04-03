//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const Style = @import("Utils/style.zig").Style; // if in a separate file

const Printer = @import("Printer/printer.zig").Printer;

const Scanner = @import("Scanner/scanner.zig");

const mem = std.mem;
const Allocator = mem.Allocator;

/// Prints out program help menu.
/// I took helper menu straight from python...
pub fn printHelp() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{s}usage:{s} {s}{s}zigterpreter{s} [option] ... [-c cmd | -m mod | file | -] [arg] ...\n\n", .{ Style.heading, Style.reset, Style.fg_magenta, Style.underline, Style.reset });

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

    // try printHelp();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const app_mem_allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) @panic("TEST FAIL");
    }

    var iter = try std.process.argsWithAllocator(app_mem_allocator);
    defer iter.deinit();

    var script_name: ?[]const u8 = null; // optinal script name

    var i: usize = 0;
    while (iter.next()) |arg| : (i += 1) {
        std.debug.print("here1\n", .{});
        if (i == 0) {
            continue;
        }

        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            try printHelp();
            return;
        } else {
            // must be a name of a zig script to execute
            try stdout.print("arg[{d}]: {s}{s}{s}\n", .{ i, Style.fg_red, arg, Style.reset });
            try bw.flush(); // Don't forget to flush!
            // copy script name. safe as long as iter is still alive
            script_name = arg;
            // script name should come after all options
            // dont parse anything after
            break;
        }

        try stdout.print("arg[{d}]: {s}\n", .{ i, arg });
        try bw.flush(); // Don't forget to flush!
    }
    std.debug.print("here2\n", .{});

    // if a script name was found run in script mode
    if (script_name) |script| {
        try stdout.print("script name:{s}\n", .{script});
        try bw.flush(); // Don't forget to flush!
        std.debug.print("here3\n", .{});
        try runScriptMode(script, app_mem_allocator);
    } else {
        // run in interpreter mode
        std.debug.print("here4\n", .{});
        try runInterpreterMode(app_mem_allocator);
    }

    // var map = std.AutoHashMap(u32, Point).init(
    //     test_allocator,
    // );
    // defer map.deinit();

    // try map.put(1525, .{ .x = 1, .y = -4 });
    // try map.put(1550, .{ .x = 2, .y = -3 });
    // try map.put(1575, .{ .x = 3, .y = -2 });
    // try map.put(1600, .{ .x = 4, .y = -1 });
}

fn runScriptMode(script_name: []const u8, app_allocator: Allocator) !void {
    _ = app_allocator;
    std.debug.print("script mode {s}\n", .{script_name});
}

fn runInterpreterMode(app_allocator: Allocator) !void {

    // run in a continous interpreter mode
    std.debug.print("interpreter mode\n", .{});

    var printer = Printer.init();

    try printer.printError("Welcome to the Zig Interpreter!\n", .{});
    try printer.printResult("=> {s}\n", .{"42"});
    try printer.printError("Syntax error at line 🔥 {}\n", .{10});

    const @"tmpé🔥" = 4;
    // const tmé = 5;
    // _=tmé;
    _ = @"tmpé🔥";

    var lex_scanner = try Scanner.Scanner.init("stdin", app_allocator);
    defer lex_scanner.deinit();

    std.debug.print("lexer {d} {s}\n", .{ lex_scanner.getLineNumber(), lex_scanner.getFileName() });
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
