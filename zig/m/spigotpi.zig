/// Generate leading decimal digits with the pinned spigot recurrence.
const MAX_DIGITS: usize = 256;
const MAX_BOXES: usize = 854;

export fn spigotpi(input: [*c]const i64, length: usize,
                   output: [*c]u8, output_capacity: usize) i64 {
    if (length != 1 or input == null or input[0] < 0 or input[0] > MAX_DIGITS) return -1;
    const digit_count: usize = @intCast(input[0]);
    if (output == null or output_capacity < digit_count) return -2;
    if (digit_count == 0) return 0;

    const boxes = digit_count * 10 / 3;
    var remainders: [MAX_BOXES]i64 = [_]i64{0} ** MAX_BOXES;
    for (0..boxes) |item| remainders[item] = 2;
    var digits_held: usize = 0;
    for (0..digit_count) |index| {
        var carried_over: i64 = 0;
        var sum: i64 = 0;
        var cursor = boxes;
        while (cursor > 0) {
            cursor -= 1;
            const j = cursor;
            remainders[j] *= 10;
            sum = remainders[j] + carried_over;
            const denominator: i64 = @intCast(j * 2 + 1);
            const quotient = @divTrunc(sum, denominator);
            remainders[j] = @rem(sum, denominator);
            carried_over = quotient * @as(i64, @intCast(j));
        }
        remainders[0] = @rem(sum, 10);
        var q = @divTrunc(sum, 10);
        if (q == 9) {
            digits_held += 1;
        } else if (q == 10) {
            q = 0;
            for (1..digits_held + 1) |offset| {
                const position = index - offset;
                output[position] = if (output[position] == '9') '0' else output[position] + 1;
            }
            digits_held = 1;
        } else {
            digits_held = 1;
        }
        output[index] = @intCast('0' + q);
    }
    return @intCast(digit_count);
}
