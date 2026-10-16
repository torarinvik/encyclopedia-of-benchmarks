package endian_converter

// Reverse the byte order of a signed 32-bit integer.
@(export)
endian_converter :: proc "c" (value: i64) -> i64 {
    if value < -2_147_483_648 || value > 2_147_483_647 do return -2_147_483_649
    bits := u32(value)
    reversed := ((bits & 0x000000ff) << 24) | ((bits & 0x0000ff00) << 8) |
                ((bits & 0x00ff0000) >> 8) | ((bits & 0xff000000) >> 24)
    if reversed <= 0x7fffffff do return i64(reversed)
    return i64(reversed) - 4_294_967_296
}
