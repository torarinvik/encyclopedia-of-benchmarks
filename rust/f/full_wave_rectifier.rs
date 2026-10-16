/// Evaluate the six pinned full-wave rectifier helper formulas.
const OUTPUT_BYTES: i64 = 48;

unsafe fn store_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bits = value.to_bits();
    for byte in 0..8 {
        *output.add(offset + byte) = ((bits >> (byte * 8)) & 255) as u8;
    }
}

#[no_mangle]
pub extern "C" fn full_wave_rectifier(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 5 { return -1; }
    let (rf_i, rs_i, rl_i, vm_i, im_i) = unsafe {
        (*values, *values.add(1), *values.add(2), *values.add(3), *values.add(4))
    };
    if rf_i < 0 || rf_i > 1_000_000 || rs_i < 0 || rs_i > 1_000_000 ||
        rl_i < 1 || rl_i > 1_000_000 || vm_i < -1_000_000 || vm_i > 1_000_000 ||
        im_i < -1_000_000 || im_i > 1_000_000 { return -1; }
    if output.is_null() || output_capacity < OUTPUT_BYTES as usize { return -2; }

    let rf = rf_i as f64;
    let rs = rs_i as f64;
    let rl = rl_i as f64;
    let vm = vm_i as f64;
    let im = im_i as f64;
    let result = [
        vm / (rf + rs + rl),
        2.0 * im * 0.318,
        2.0 * 0.318 * vm,
        vm / rl,
        im * 0.707,
        vm * 0.707,
    ];
    for (index, value) in result.iter().enumerate() {
        unsafe { store_f64_le(output, index * 8, *value); }
    }
    OUTPUT_BYTES
}
