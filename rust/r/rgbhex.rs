#[no_mangle]
pub unsafe extern "C" fn rgbhex(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let values = std::slice::from_raw_parts(input, 4);
    let (op, x, y, z) = (values[0], values[1], values[2], values[3]);
    if op == 0 {
        if x < 0 || x > 4_294_967_295 || y != 0 || z != 0 { return -1; }
        return x & 0x00ff_ffff;
    }
    if op == 1 {
        if !(0..=255).contains(&x) || !(0..=255).contains(&y) || !(0..=255).contains(&z) { return -1; }
        return (x << 16) | (y << 8) | z;
    }
    -1
}
