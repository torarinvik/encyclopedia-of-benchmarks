/// Exact perfect-square check using bounded integer binary search.
export fn perfect_square(input: i64) i64 {
    if (input < 0) return 0;
    if (input < 2) return 1;
    const number: u64 = @intCast(input);
    if (((@as(u64, 0x0213) >> @as(u6, @intCast(number & 15))) & 1) == 0) return 0;
    var low: u64 = 1;
    const root_limit: u64 = if (number <= 0xffffffff) 65_535 else 3_037_000_499;
    var high = @min(number / 2, root_limit);
    while (low <= high) {
        const middle = (low + high) >> 1;
        const square = middle * middle;
        if (square == number) return 1;
        if (square < number) {
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return 0;
}
