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
    line_number: usize,
    /// current offset from beginning of file/stdin while scanning
    file_offset: usize,
    /// absolute file path to the file being scanned or "<stdin>" if stdin is being used
    file_name: []u8,
    ///
    allocator: Allocator,

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
        self.allocator.free(self.file_name);
    }

    pub fn getLineNumber(self: *Scanner) usize {
        return self.line_number;
    }

    pub fn getFileName(self: *Scanner) []u8 {
        return self.file_name;
    }

    /// Feed new input (line or chunk) to the scanner
    pub fn addChunk(self: *Scanner, chunk: []const u8) !void {
        try self.buffer.appendSlice(self.allocator, chunk);
    }

    /// Advance and produce the next token
    pub fn nextToken(self: *Scanner) ?Token {
        // Skip whitespace
        while (self.cursor < self.buffer.items.len) {
            const c = self.buffer.items[self.cursor];
            if (c == ' ' or c == '\t') {
                self.cursor += 1;
                self.file_offset += 1;
            } else if (c == '\n') {
                self.cursor += 1;
                self.line_number += 1;
                self.file_offset = 0;
            } else {
                break;
            }
        }

        if (self.cursor >= self.buffer.items.len) return null;

        const start = self.cursor;

        // Identifier or keyword
        if (std.ascii.isAlphabetic(self.buffer.items[self.cursor])) {
            self.cursor += 1;
            while (self.cursor < self.buffer.items.len and std.ascii.isAlphanumeric(self.buffer.items[self.cursor])) {
                self.cursor += 1;
            }

            const lexeme = self.buffer.items[start..self.cursor];
            const kind = KeywordMap.get(lexeme) orelse TokenType.Identifier;

            return Token{
                .kind = kind,
                .lexeme = lexeme,
                .line = self.line_number,
                .offset = self.file_offset,
            };
        }

        // Operator
        for (1..2) |len| {
            const end = @min(self.cursor + len, self.buffer.items.len);
            const lexeme = self.buffer.items[self.cursor..end];
            if (OperatorMap.get(lexeme)) |kind| {
                self.cursor += len;
                return Token{
                    .kind = kind,
                    .lexeme = lexeme,
                    .line = self.line_number,
                    .offset = self.file_offset,
                };
            }
        }

        // Unknown character (could expand error handling here)
        self.cursor += 1;
        return null;
    }
};
