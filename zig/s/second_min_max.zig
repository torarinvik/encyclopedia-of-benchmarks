const INVALID_RESULT: i64 = -9223372036854775807 - 1;
const MAX_INPUT_LENGTH: usize = 259;
const INT32_MIN_VALUE: i64 = -2_147_483_648;
const INT32_MAX_VALUE: i64 = 2_147_483_647;

export fn second_min_max(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    const operation = values[0];
    const raw_count = values[1];
    if ((operation != 0 and operation != 1) or raw_count < 2 or raw_count > 256) return INVALID_RESULT;
    const count: usize = @intCast(raw_count);
    if (length != count + 2) return INVALID_RESULT;
    const initial = if (operation == 0) INT32_MAX_VALUE else INT32_MIN_VALUE;
    var best = initial;
    var second = initial;
    for (values[2..]) |value| {
        if (value < INT32_MIN_VALUE or value > INT32_MAX_VALUE) return INVALID_RESULT;
        const better = if (operation == 0) value < best else value > best;
        if (better) {
            second = best;
            best = value;
        } else {
            const improves_second = if (operation == 0) value < second else value > second;
            if (improves_second and value != best) second = value;
        }
    }
    return if (second == initial) INVALID_RESULT else second;
}
