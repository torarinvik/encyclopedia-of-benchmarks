fn put32(out: &mut [u8], value: u32) {
    out[..4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn evaluate_expression(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 131 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count = values[0];
    if !(1..=64).contains(&count) || length != (1 + 2 * count) as usize { return -1; }
    let mut stack = [0.0f64; 64];
    let mut depth = 0usize;
    let mut valid = true;
    for i in 0..count as usize {
        let op = values[1 + 2 * i];
        let payload = values[2 + 2 * i];
        if op == 0 {
            if !(-1_000_000_000..=1_000_000_000).contains(&payload) { return -1; }
            stack[depth] = payload as f64 / 1000.0;
            depth += 1;
        } else if (1..=4).contains(&op) {
            if payload != 0 { return -1; }
            if depth < 2 { valid = false; break; }
            depth -= 1;
            let right = stack[depth];
            depth -= 1;
            let left = stack[depth];
            if op == 1 { stack[depth] = left + right; }
            else if op == 2 { stack[depth] = left - right; }
            else if op == 3 { stack[depth] = left * right; }
            else if right == 0.0 { valid = false; break; }
            else { stack[depth] = left / right; }
            depth += 1;
        } else { valid = false; break; }
    }
    valid &= depth == 1;
    let needed = if valid { 12 } else { 4 };
    if output.is_null() || capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, needed);
    put32(out, if valid { 1 } else { 0 });
    if valid { out[4..12].copy_from_slice(&stack[0].to_bits().to_le_bytes()); }
    needed as i64
}
