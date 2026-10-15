/// Convert an ASCII Excel column title to its one-based column number.
export fn excel_title_to_column(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > 13) return -1;
    const count = values[0];
    if (count < 1 or count > 12 or length != 1 + @as(usize, @intCast(count))) return -1;

    var column: i64 = 0;
    for (0..@as(usize, @intCast(count))) |index| {
        var letter = values[1 + index];
        if (letter >= 97 and letter <= 122) letter -= 32;
        if (letter < 65 or letter > 90) return -1;
        column = column * 26 + (letter - 65 + 1);
    }
    return column;
}
