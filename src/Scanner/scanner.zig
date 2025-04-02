const std = @import("std");

const mem = std.mem;
const Allocator = mem.Allocator;

const TokenType = enum {
    Identifier,
    KeywordIf,
    KeywordElse,
    KeywordWhile,
    KeywordFn,
    // ... more
};

const KeywordMap = std.ComptimeStringMap(TokenType, .{
    .{ "if", .KeywordIf },
    .{ "else", .KeywordElse },
    .{ "while", .KeywordWhile },
    .{ "fn", .KeywordFn },
    // add all Zig keywords
});

const OperatorMap = std.ComptimeStringMap(TokenType, .{
    .{ "+", .Plus },
    .{ "-", .Minus },
    .{ "==", .EqualEqual },
    // ...
});

const Scanner = struct {
    /// current line number in the file/stdin while scanning
    line_number_: usize,
    /// current offset from beginning of file/stdin while scanning
    file_offset_: usize,
    /// absolute file path to the file being scanned or "<stdin>" if stdin is being used
    file_name_: []const u8,

    ///
    stdin_mode: bool,

    ///
    allocator_: Allocator,

    pub fn init(file_path: []const u8, allocator: Allocator) !Scanner {

        // check if stdin
        var stdin_mode_ = false;
        if (std.mem.eql(u8, file_path, "stdin")) {
            stdin_mode_ = true;
        }

        var scanner = Scanner{ .line_number_ = 0, .file_offset_ = 0, .stdin_mode = stdin_mode_, .allocator_ = allocator };

        // check if file is valid
        // copy the file path
        scanner.line_number_ = 0;
        scanner.file_name_ = scanner.allocator_.alloc(u8, file_path.len);
        std.mem.copyForwards(u8, scanner.file_name_, file_path);

        return scanner;
    }

    pub fn deinit(self: *Scanner) !void {
        // free up memory used to save the file name
        self.allocator_.free(self.file_name_);
    }
};
