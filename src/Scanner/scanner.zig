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

pub const Token = struct {
    kind: TokenType,
    lexeme: []const u8,
    line: usize,
    offset: usize,
};

pub const Scanner = struct {
    /// current line number in the file/stdin while scanning
    line_number_: usize,
    /// current offset from beginning of file/stdin while scanning
    file_offset_: usize,
    /// absolute file path to the file being scanned or "<stdin>" if stdin is being used
    file_name_: []u8,
    ///
    allocator_: Allocator,

    buffer: std.ArrayListUnmanaged(u8),
    cursor: usize,

    pub fn init(file_name: []const u8, allocator: Allocator) !Scanner {
        return Scanner{
            .allocator = allocator,
            .buffer = .{},
            .cursor = 0,
            .line_number = 1,
            .file_offset = 0,
            .file_name = try allocator.dupe(u8, file_name),
        };
    }

    pub fn deinit(self: *Scanner) void {
        // free up memory used to save the file name
        self.buffer.deinit(self.allocator);
        self.allocator_.free(self.file_name_);
    }

    pub fn getLineNumber(self: *Scanner) usize {
        return self.line_number_;
    }

    pub fn getFileName(self: *Scanner) []u8 {
        return self.file_name_;
    }

    /// Feed new input (line or chunk) to the scanner
    pub fn addChunk(self: *Scanner, chunk: []const u8) !void {
        try self.buffer.appendSlice(self.allocator, chunk);
    }

    pub fn nextToken(self: *Scanner) !void {
        _ = self;
    }
};
