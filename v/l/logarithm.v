module logarithm

@[export: 'logarithm']
pub fn logarithm(input i64) i64 {
    if input < 1 || input > 4_294_967_295 { return -1 }
    mut value := u32(input)
    mut result := i64(0)
    if value & u32(0xFFFF0000) != 0 { value >>= 16; result += 16 }
    if value & u32(0x0000FF00) != 0 { value >>= 8; result += 8 }
    if value & u32(0x000000F0) != 0 { value >>= 4; result += 4 }
    if value & u32(0x0000000C) != 0 { value >>= 2; result += 2 }
    if value & u32(0x00000002) != 0 { result += 1 }
    return result
}
