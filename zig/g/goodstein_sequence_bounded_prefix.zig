const MAX_INPUT_WORDS: usize = 3;
const MAX_TRANSITIONS: i64 = 16;

fn smallPower(base: i64, exponent: i64) i64 {
    var result: i64 = 1;
    var index: i64 = 0;
    while (index < exponent) : (index += 1) result *= base;
    return result;
}

fn rebaseHereditary(value: i64, base: i64, raised_base: i64) i64 {
    if (value == 0) return 0;
    var result: i64 = 0;
    var place: i64 = 1;
    var exponent: i64 = 0;
    while (place <= value) : ({ place *= base; exponent += 1; }) {
        const digit = @mod(@divTrunc(value, place), base);
        if (digit != 0) {
            const raised_exponent = rebaseHereditary(exponent, base, raised_base);
            result += digit * smallPower(raised_base, raised_exponent);
        }
    }
    return result;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn goodstein_sequence_bounded_prefix(raw: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const input = raw orelse return -1;
    if (length < 1 or length > MAX_INPUT_WORDS or length != 2) return -1;
    const start = input[0];
    const transitions = input[1];
    if (start < 0 or start > 4 or transitions < 0 or transitions > MAX_TRANSITIONS) return -1;

    var terms = [_]i64{0} ** 17;
    var count: usize = 1;
    terms[0] = start;
    var current = start;
    var base: i64 = 2;
    var step: i64 = 0;
    while (step < transitions and current != 0) : (step += 1) {
        current = rebaseHereditary(current, base, base + 1) - 1;
        base += 1;
        terms[count] = current;
        count += 1;
    }

    const output_bytes = (count + 1) * 8;
    const destination = output orelse return -2;
    if (capacity < output_bytes) return -2;
    storeI64Le(destination, 0, @intCast(count));
    for (0..count) |index| storeI64Le(destination, (index + 1) * 8, terms[index]);
    return @intCast(output_bytes);
}
