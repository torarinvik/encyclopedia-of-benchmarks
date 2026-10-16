#[no_mangle]
pub extern "C" fn logarithm(input: i64) -> i64 {
    if !(1..=4_294_967_295).contains(&input) {
        return -1;
    }
    let mut value = input as u32;
    let mut result = 0i64;
    if value & 0xFFFF_0000 != 0 { value >>= 16; result += 16; }
    if value & 0x0000_FF00 != 0 { value >>= 8; result += 8; }
    if value & 0x0000_00F0 != 0 { value >>= 4; result += 4; }
    if value & 0x0000_000C != 0 { value >>= 2; result += 2; }
    if value & 0x0000_0002 != 0 { result += 1; }
    result
}
