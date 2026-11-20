//! Uncompiled monotone-cursor Prüfer decoder draft.
#[no_mangle]
pub unsafe extern "C" fn prufer_decode_linear(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=4096).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let nv = values[0];
    if !(2..=4096).contains(&nv) || length != nv as usize - 1 { return -1; }
    let n = nv as usize;
    let mut count = [0i32;4096];
    for &v in &values[1..] {
        if v < 0 || v >= nv { return -1; }
        count[v as usize] += 1;
    }
    let needed = 16*(n-1);
    if output.is_null() || capacity < needed { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, needed) };
    let mut cursor = n-1;
    while count[cursor] != 0 { cursor -= 1; }
    let mut leaf = cursor;
    for (i, &raw) in values[1..].iter().enumerate() {
        let v = raw as usize;
        out[16*i..16*i+8].copy_from_slice(&(leaf as i64).to_le_bytes());
        out[16*i+8..16*i+16].copy_from_slice(&raw.to_le_bytes());
        count[leaf] = -1; count[v] -= 1;
        if count[v] == 0 && v > cursor { leaf = v; }
        else { cursor -= 1; while count[cursor] != 0 { cursor -= 1; } leaf = cursor; }
    }
    let other = (0..n).find(|&v| v != leaf && count[v] == 0).unwrap();
    out[16*(n-2)..16*(n-2)+8].copy_from_slice(&(leaf as i64).to_le_bytes());
    out[16*(n-2)+8..16*(n-1)].copy_from_slice(&(other as i64).to_le_bytes());
    needed as i64
}
