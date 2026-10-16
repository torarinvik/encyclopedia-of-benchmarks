const INVALID_RESULT: i64 = -9223372036854775807 - 1;

pub export fn ipv4_conversion(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 4) return INVALID_RESULT;
    var address: i64 = 0;
    for (0..4) |index| {
        const octet = input[index];
        if (octet < 0 or octet > 255) return INVALID_RESULT;
        address = address * 256 + octet;
    }
    return address;
}
