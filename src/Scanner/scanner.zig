const std = @import("std");

const mem = std.mem;
const Allocator = mem.Allocator;

/// Scanner/Lexer emits syntax tokens. No knowledge of grammer rules.
/// Should be unambigous and context-free.
///
/// Its the parser job to say: AtSign + String = quoted identifier
/// @ tokens:
///     @"..." - identifier escape sequence
///     @identifier - built in function call
///
/// @+string = quoted identifier
///
/// identifier: type
///
///
const TokenType = enum {
    Identifier,
    String,
    MultilineString,
    Character,
    Comment, // or double slashed line
    DocComment,

    // literals
    IntegerLiteral,
    FloatingLiteral,

    // syntax
    AtSign, // @
    Underscore, // _
    Equal, // =
    LeftBrace, // {
    RightBrace, // }
    Comma, // ,
    Dot, // .
    LeftParenthesis, // (
    RightParenthesis, // )
    LeftBracket, // [
    RightBracket, // ]
    Plus, // +
    Minus, // -
    Star, // *
    ForwardSlash, // /
    Colon, // :
    Semicolon, // ;
    LessThan, // <
    GreaterThan, // >
    LessThanOrEquals, // <
    GreaterThanOrEquals, // >
    DoubleEquals, // ==
    DoubleMinus, // --
    DoublePlus, // ++
    DoubleStar, // **

    KeywordIf,
    KeywordElse,
    KeywordWhile,
    KeywordFn,
    KeywordConst,
    KeywordPub,
    KeywordOr,
    KeywordAnd,
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

pub const ScannerError = error{
    BufferOverflow,
    InvalidUtf8,
    UnterminatedString,
};

const MAX_BUFFER_SIZE = 64 * 1024; // 64 KB

pub const Scanner = struct {
    /// current line number in the file/stdin while scanning
    line_number: usize,
    /// current offset from beginning of file/stdin while scanning
    file_offset: usize,
    /// absolute file path to the file being scanned or "<stdin>" if stdin is being used
    file_name: []u8,
    ///
    allocator: Allocator,

    /// we buffer input while we are processing it
    buffer: std.ArrayListUnmanaged(u8),
    /// cursor points to where we are in the buffer
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
        // const temp: i32 = block_label: {
        //     break :block_label 2;
        // };
        // _ = temp;
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
        // note: should we prevent from buffering too much data without first processing some existing tokens?
        // note: for example if addChunk gets called for a super large file all at once?
        if (self.buffer.items.len + chunk.len > MAX_BUFFER_SIZE) {
            return ScannerError.BufferOverflow;
        }
        try self.buffer.appendSlice(self.allocator, chunk);
    }

    /// Advance and produce the next token
    pub fn nextToken(self: *Scanner) !?Token {
        // Skip whitespace

        if (self.cursor >= self.buffer.items) {
            // the cursor cannot point past the end of buffer
            return ScannerError.BufferOverflow;
        }

        if (self.cursor >= MAX_BUFFER_SIZE - 1024) {
            // buffer almost full. reclaim space 🔥
            compactBuffer(self);
        }

        var utf8_iterator = std.unicode.Utf8Iterator{ .bytes = self.buffer.items, .i = 0 };
        //_ = utf8_iterator;

        while (utf8_iterator.nextCodepoint()) |codepoint| {
            if (!std.ascii.isAscii(codepoint)) {
                // UTF8 characters only allowed inside escaped identifiers or comments
                return ScannerError.InvalidUtf8;
            }

            switch (codepoint) {
                '(' => {
                    self.cursor = self.cursor + 1;
                    return Token{ .kind = TokenType.LeftParenthesis, .line = self.line_number, .offset = self.file_offset, .lexeme = "" };
                },
                ')' => {},
                else => unreachable,
            }

            if (std.ascii.isWhitespace(codepoint)) {
                // note: zig does not check for narrowing converison for runtime variables
                // note: this means that it passes a u21 to isWhitespace as a u8 by truncating the number during runtime.
                // note: its up to us to make sure this is ok.
                std.debug.print("whitespace {c}", .{codepoint});
                // note silently skip whitespace characters
                continue;
            } else if (std.ascii.isAlphanumeric(codepoint)) {
                // note identifier or keyword. start matching
                // note matching function advances the cursor automatically if a match happens
                // start parsing identifier
            } else {
                // note: skip non ascii codepoint for now. will come back to handling those later
            }
            const tmp = "🔥";
            _ = tmp;

            //if(c)

        }
        return null;
    }

    /// Reclaim used space by shifting unprocessed bytes to the front
    /// This function should be called internally by our scanner to reclaim space
    /// we know that we already processed all tokens 0..cursor so we
    /// can safely discard old data
    /// When should this function get called? When we processed enough of the input but not too often because
    /// we dont want too much copying. For example we should not call this after every token.
    /// one idea is we could call this once our cursor gets big. Lets say close to our buffer end.
    fn compactBuffer(self: *Scanner) void {
        if (self.cursor == 0) return;

        const remaining = self.buffer.items[self.cursor..];
        std.mem.copyForwards(u8, self.buffer.items[0..remaining.len], remaining);
        self.buffer.items.len = remaining.len;
        self.cursor = 0;
    }
};

test "create a scanner" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    var lex_scanner = try Scanner.init("stdin", allocator);
    defer lex_scanner.deinit();

    std.testing.expect(false);
}
