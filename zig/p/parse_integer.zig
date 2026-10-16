const INVALID_RESULT: i64 = -9223372036854775807 - 1;
const UINT32_MODULUS: i64 = 4_294_967_296;

/// Parse an ASCII decimal string with Java int32 wraparound semantics.
export fn parse_integer(bytes: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 64) return INVALID_RESULT;
    for (0..length) |index| {
        if (bytes[index] < 0 or bytes[index] > 127) return INVALID_RESULT;
    }
    const negative = bytes[0] == 45;
    var index: usize = if (bytes[0] == 45 or bytes[0] == 43) 1 else 0;
    var number: i64 = 0;
    while (index < length) : (index += 1) {
        const byte = bytes[index];
        if (byte < 48 or byte > 57) return INVALID_RESULT;
        number = @mod(number * 10 + byte - 48, UINT32_MODULUS);
    }
    if (negative and number != 0) number = UINT32_MODULUS - number;
    if (number >= 2_147_483_648) return number - UINT32_MODULUS;
    return number;
}
