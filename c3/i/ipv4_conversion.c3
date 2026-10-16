module ipv4_conversion;

const long INVALID_RESULT = -9223372036854775807L - 1L;

fn long ipv4_conversion(long* input, usz length) @export("ipv4_conversion") {
    if (input == null || length != 4) return INVALID_RESULT;
    long address = 0;
    for (usz index = 0; index < 4; index++) {
        long octet = input[index];
        if (octet < 0 || octet > 255) return INVALID_RESULT;
        address = address * 256 + octet;
    }
    return address;
}
