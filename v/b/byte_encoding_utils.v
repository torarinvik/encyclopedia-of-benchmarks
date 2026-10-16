module byte_encoding_utils

// Reverse the eight bytes in a 64-bit bit pattern.
@[export: 'byte_encoding_utils']
pub fn byte_encoding_utils(value i64) i64 {
    bits := u64(value)
    reversed := ((bits & u64(0x00000000000000ff)) << 56) |
                ((bits & u64(0x000000000000ff00)) << 40) |
                ((bits & u64(0x0000000000ff0000)) << 24) |
                ((bits & u64(0x00000000ff000000)) << 8) |
                ((bits & u64(0x000000ff00000000)) >> 8) |
                ((bits & u64(0x0000ff0000000000)) >> 24) |
                ((bits & u64(0x00ff000000000000)) >> 40) |
                ((bits & u64(0xff00000000000000)) >> 56)
    if reversed <= u64(0x7fffffffffffffff) { return i64(reversed) }
    return -1 - i64(u64(0xffffffffffffffff) - reversed)
}
