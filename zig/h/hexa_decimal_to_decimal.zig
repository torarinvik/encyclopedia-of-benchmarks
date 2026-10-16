const MAX_INPUT_LENGTH: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 65;
const INVALID_RESULT: i64 = -2_147_483_649;
const UINT32_MODULUS: u64 = 4_294_967_296;

export fn hexa_decimal_to_decimal(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (length == 0) return 0;
    if (length > MAX_INPUT_LENGTH or input == null) return INVALID_RESULT;

    var accumulator: u64 = 0;
    for (0..length) |index| {
        const code = input[index];
        const digit: i64 = if (code >= 48 and code <= 57) code - 48
            else if (code >= 65 and code <= 70) code - 55
            else if (code >= 97 and code <= 102) code - 87
            else return INVALID_RESULT;
        accumulator = @mod(accumulator * 16 + @as(u64, @intCast(digit)), UINT32_MODULUS);
    }
    if (accumulator <= 2_147_483_647) return @intCast(accumulator);
    return @as(i64, @intCast(accumulator)) - 4_294_967_296;
}
