pub const Style = struct {
    pub const reset = "\x1b[0m";

    // Text styles
    pub const bold = "\x1b[1m";
    pub const underline = "\x1b[4m";

    // Foreground colors
    pub const fg_red = "\x1b[31m";
    pub const fg_green = "\x1b[32m";
    pub const fg_yellow = "\x1b[33m";
    pub const fg_blue = "\x1b[34m";
    pub const fg_magenta = "\x1b[35m";
    pub const fg_cyan = "\x1b[36m";
    pub const fg_white = "\x1b[37m";

    // Background colors (optional)
    pub const bg_gray = "\x1b[48;5;236m";
    pub const bg_black = "\x1b[40m";

    // Composite styles
    pub const heading = "\x1b[1;34m"; // Bold blue
    pub const flag = "\x1b[1;33m"; // Bold yellow
    pub const example = "\x1b[36m"; // Cyan
    pub const error_style = "\x1b[1;31m"; // Bold red
};
