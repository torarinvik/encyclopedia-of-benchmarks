module endian_converter

const invalid_result = i64(-2_147_483_649)

// Reverse the byte order of a signed 32-bit integer.
@[export: 'endian_converter']
pub fn endian_converter(value i64) i64 {
    if value < -2_147_483_648 || value > 2_147_483_647 { return invalid_result }
    bits := u32(value)
    reversed := ((bits & u32(0x000000ff)) << 24) | ((bits & u32(0x0000ff00)) << 8) |
                ((bits & u32(0x00ff0000)) >> 8) | ((bits & u32(0xff000000)) >> 24)
    if reversed <= u32(0x7fffffff) { return i64(reversed) }
    return i64(reversed) - 4_294_967_296
}
