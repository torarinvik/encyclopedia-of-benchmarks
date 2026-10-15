const INVALID_RESULT: i64 = -2_147_483_649;

/// Reverse a signed 32-bit decimal integer, returning zero on overflow.
export fn reverse_integer(input_value: i64) i64 {
    if (input_value < -2_147_483_648 or input_value > 2_147_483_647) return INVALID_RESULT;
    var input = input_value;
    var reversed: i64 = 0;
    while (input != 0) {
        const digit = @rem(input, 10);
        input = @divTrunc(input, 10);
        if (reversed > 214_748_364 or (reversed == 214_748_364 and digit > 7)) return 0;
        if (reversed < -214_748_364 or (reversed == -214_748_364 and digit < -8)) return 0;
        reversed = reversed * 10 + digit;
    }
    return reversed;
}
