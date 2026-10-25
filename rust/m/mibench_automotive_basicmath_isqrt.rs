#[no_mangle]
pub unsafe extern "C" fn mibench_automotive_basicmath_isqrt(input: *const i64,
                                                              length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let value = *input;
    if !(0..=65_535).contains(&value) { return -1; }
    let mut x = value as u32;
    let mut root = 0_u32;
    let mut remainder = 0_u32;
    for _ in 0..32 {
        remainder = (remainder << 2) + (x >> 30);
        x <<= 2;
        root <<= 1;
        let trial = (root << 1) + 1;
        if remainder >= trial {
            remainder -= trial;
            root += 1;
        }
    }
    root as i64
}
