fn put_i64(out: &mut [u8], value: i64) { out[..8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn dc_tree_k_server_path(input: *const i64, length: usize,
                                                  output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > 18 { return -1; }
    let a = std::slice::from_raw_parts(input, length);
    let (k0, q0) = (a[0], a[1]);
    if !(2..=4).contains(&k0) || !(1..=12).contains(&q0) { return -1; }
    let (k, q) = (k0 as usize, q0 as usize);
    if length != 2 + k + q { return -1; }
    let mut pos = [0i64; 4];
    for i in 0..k { pos[i] = a[2+i]; if !(0..=15).contains(&pos[i]) { return -1; } }
    for r in 0..q { if !(0..=15).contains(&a[2+k+r]) { return -1; } }
    let mut staged = [0i64; 60];
    let mut at = 0;
    for r in 0..q {
        let target = a[2+k+r];
        let mut active = [false; 4];
        let mut active_count = 0usize;
        let mut nearest = i64::MAX;
        for i in 0..k {
            if (0..i).any(|j| pos[j] == pos[i]) { continue; }
            active[i] = true; active_count += 1;
            nearest = nearest.min((pos[i]-target).abs());
        }
        staged[at] = nearest * active_count as i64; at += 1;
        for i in 0..k { if active[i] { pos[i] += if pos[i] < target { nearest } else if pos[i] > target { -nearest } else { 0 }; } }
        for i in 0..k { staged[at] = pos[i]; at += 1; }
    }
    let bytes = 8*q*(k+1);
    if output.is_null() || capacity < bytes { return -2; }
    let out = std::slice::from_raw_parts_mut(output, bytes);
    for i in 0..at { put_i64(&mut out[8*i..8*i+8], staged[i]); }
    bytes as i64
}
