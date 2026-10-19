const MAX_CALL_COUNT: i64 = 1_000_000;
const MODULUS: i64 = 139_968;
const FRACTION_SCALE: i64 = 1_000_000_000;
const MAX_OUTPUT_BYTES: usize = 13;

export fn shootout_random(call_count: i64, output_opt: ?[*]u8,
    output_capacity: usize) i64 {
    if (call_count < 1 or call_count > MAX_CALL_COUNT) return -1;

    var state: i64 = 42;
    var call: i64 = 0;
    while (call < call_count) : (call += 1)
        state = @mod(state * 3877 + 29_573, MODULUS);

    const scaled = @divTrunc(100 * state * FRACTION_SCALE + MODULUS / 2, MODULUS);
    var whole = @divTrunc(scaled, FRACTION_SCALE);
    var fraction = @mod(scaled, FRACTION_SCALE);
    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var reversed_digits: [3]u8 = undefined;
    var digit_count: usize = 0;
    while (true) {
        reversed_digits[digit_count] = @intCast(48 + @mod(whole, 10));
        digit_count += 1;
        whole = @divTrunc(whole, 10);
        if (whole == 0) break;
    }

    var used: usize = 0;
    while (digit_count > 0) {
        digit_count -= 1;
        staged[used] = reversed_digits[digit_count];
        used += 1;
    }
    staged[used] = '.';
    used += 1;
    var place: i64 = 100_000_000;
    while (place > 0) {
        staged[used] = @intCast(48 + @divTrunc(fraction, place));
        used += 1;
        fraction = @mod(fraction, place);
        place = @divTrunc(place, 10);
    }
    staged[used] = '\n';
    used += 1;

    if (output_opt == null or output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
