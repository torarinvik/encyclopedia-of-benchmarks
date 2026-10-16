const MAX_ITEMS: usize = 12;

fn put32(out: &mut [u8], pos: &mut usize, value: u32) {
    out[*pos..*pos + 4].copy_from_slice(&value.to_le_bytes());
    *pos += 4;
}

fn emit_subsets(input: &[i64], n: usize, index: usize, mask: usize, selected: u32,
                out: &mut [u8], pos: &mut usize) {
    if index == n {
        put32(out, pos, selected);
        for i in 0..n {
            if mask & (1usize << i) != 0 { out[*pos] = input[i + 1] as u8; *pos += 1; }
        }
        return;
    }
    emit_subsets(input, n, index + 1, mask | (1usize << index), selected + 1, out, pos);
    emit_subsets(input, n, index + 1, mask, selected, out, pos);
}

#[no_mangle]
pub unsafe extern "C" fn generate_subsets_recursive(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_ITEMS + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_ITEMS as i64 { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1..].iter().any(|v| *v < 0 || *v > 127) { return -1; }
    let subsets = 1usize << n;
    let needed = 4 + 4 * subsets + n * (subsets / 2);
    if output.is_null() || capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, needed);
    let mut pos = 0;
    put32(out, &mut pos, subsets as u32);
    emit_subsets(values, n, 0, 0, 0, out, &mut pos);
    pos as i64
}
