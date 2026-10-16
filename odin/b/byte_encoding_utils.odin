package byte_encoding_utils

// Reverse the eight bytes in a 64-bit bit pattern.
@(export)
byte_encoding_utils :: proc "c" (value: i64) -> i64 {
    bits := u64(value)
    reversed := ((bits & 0x00000000000000ff) << 56) |
                ((bits & 0x000000000000ff00) << 40) |
                ((bits & 0x0000000000ff0000) << 24) |
                ((bits & 0x00000000ff000000) << 8) |
                ((bits & 0x000000ff00000000) >> 8) |
                ((bits & 0x0000ff0000000000) >> 24) |
                ((bits & 0x00ff000000000000) >> 40) |
                ((bits & 0xff00000000000000) >> 56)
    if reversed <= 0x7fffffffffffffff do return i64(reversed)
    return -1 - i64(0xffffffffffffffff - reversed)
}
