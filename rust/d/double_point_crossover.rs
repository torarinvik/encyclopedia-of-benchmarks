fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    unsafe { std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn double_point_crossover(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 7 || length > 131 { return -1; }
    let n = *input; let j1 = *input.add(1); let j2 = *input.add(2);
    if !(2..=64).contains(&n) || length != (3 + 2 * n) as usize || j1 < 1 || j1 >= j2 || j2 > n { return -1; }
    for i in 0..(2 * n) as usize { let gene = *input.add(3 + i); if !(-2147483648..=2147483647).contains(&gene) { return -1; } }
    let count = n as usize; let bytes = 16 * count;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..count {
        let mut child1 = *input.add(3 + i); let mut child2 = *input.add(3 + count + i);
        if i >= j1 as usize && i < j2 as usize { std::mem::swap(&mut child1, &mut child2); }
        put_i64_le(output, i * 8, child1); put_i64_le(output, (count + i) * 8, child2);
    }
    bytes as i64
}
