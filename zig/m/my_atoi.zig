const MAX_INPUT_LENGTH: usize = 256;
const INT32_MAX_VALUE: i64 = 2_147_483_647;
const INT32_MIN_MAGNITUDE: i64 = 2_147_483_648;
const INVALID_RESULT: i64 = -9_223_372_036_854_775_807 - 1;

export fn my_atoi(input: ?[*]const i64, length: usize) i64 {
    if (input == null) return 0;
    if (length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?;
    for (0..length) |i| if (values[i] < 0 or values[i] > 127) return INVALID_RESULT;

    var start: usize = 0;
    var end = length;
    while (start < end and values[start] <= 32) : (start += 1) {}
    while (end > start and values[end - 1] <= 32) : (end -= 1) {}
    if (start == end) return 0;

    var negative = false;
    if (values[start] == 43 or values[start] == 45) {
        negative = values[start] == 45;
        start += 1;
    }
    const limit = if (negative) INT32_MIN_MAGNITUDE else INT32_MAX_VALUE;
    var magnitude: i64 = 0;
    while (start < end and values[start] >= 48 and values[start] <= 57) : (start += 1) {
        const digit = values[start] - 48;
        if (magnitude > @divTrunc(limit, 10) or
            (magnitude == @divTrunc(limit, 10) and digit > @rem(limit, 10))) {
            return if (negative) -INT32_MIN_MAGNITUDE else INT32_MAX_VALUE;
        }
        magnitude = magnitude * 10 + digit;
    }
    return if (negative) -magnitude else magnitude;
}
