// Copyright (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
#[no_mangle]
pub unsafe extern "C" fn prolangs_c_loader_relocation_add(input: *const i64,
    length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(3..=5).contains(&length) { return -1; }
    let half_bytes = *input;
    let delta = *input.add(1);
    if !(1..=6).contains(&half_bytes) || !(-65535..=65535).contains(&delta) { return -1; }
    let width = ((half_bytes + 1) / 2) as usize;
    if length != 2 + width { return -1; }
    let mut field = 0u32;
    for i in 0..width {
        let byte = *input.add(2 + i);
        if !(0..=255).contains(&byte) { return -1; }
        field = field * 256 + byte as u32;
    }
    let adjusted = field as i64 + delta;
    if adjusted < 0 { return -1; }
    if capacity < width || output.is_null() { return -2; }
    let mut result = adjusted as u32;
    for i in (0..width).rev() { *output.add(i) = (result & 255) as u8; result >>= 8; }
    width as i64
}
