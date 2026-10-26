const MAX_N: usize = 31;
const MAX_OUTPUT: usize = 256;
fn put_i64(out: &mut [u8; MAX_OUTPUT], offset: usize, value: i64) { out[offset..offset + 8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub extern "C" fn technology_mapping_minimum_area_tree_cover(input: *const i64, length: usize,
                                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 9 || length > 99 { return -1; }
    let v = unsafe { std::slice::from_raw_parts(input, length) };
    if v[0] < 1 || v[0] > 31 { return -1; }
    let n = v[0] as usize; if length != 6 + 3 * n { return -1; }
    let mut costs = [0i64; 5];
    for p in 0..5 { costs[p] = v[1 + p]; if costs[p] != -1 && !(1..=1_000_000).contains(&costs[p]) { return -1; } }
    let mut kind = [0i32; MAX_N]; let mut left = [-1i32; MAX_N]; let mut right = [-1i32; MAX_N]; let mut parents = [0i32; MAX_N];
    for i in 0..n { let at = 6 + 3 * i; let k = v[at]; let l = v[at + 1]; let r = v[at + 2]; if !(0..=2).contains(&k) { return -1; }
        kind[i] = k as i32; left[i] = l as i32; right[i] = r as i32;
        if k == 0 { if l != -1 || r != -1 { return -1; } }
        else if k == 1 { if l <= i as i64 || l >= n as i64 || r != -1 { return -1; } parents[l as usize] += 1; }
        else { if l <= i as i64 || l >= n as i64 || r <= i as i64 || r >= n as i64 || l == r { return -1; } parents[l as usize] += 1; parents[r as usize] += 1; }
    }
    if parents[0] != 0 || parents[1..n].iter().any(|&x| x != 1) { return -1; }
    let mut best = [i64::MAX / 4; MAX_N]; let mut choice = [-1i32; MAX_N];
    for i in (0..n).rev() { if kind[i] == 0 { best[i] = 0; continue; } let l = left[i] as usize;
        if kind[i] == 1 { if costs[0] >= 0 { let candidate = costs[0] + best[l]; if candidate < i64::MAX / 4 { best[i] = candidate; choice[i] = 0; } } }
        else { let r = right[i] as usize;
            let mut consider = |p: usize, value: i64| { if costs[p] >= 0 && value < i64::MAX / 4 && value < best[i] { best[i] = value; choice[i] = p as i32; } };
            consider(1, costs[1] + best[l] + best[r]);
            if kind[l] == 1 { consider(2, costs[2] + best[left[l] as usize] + best[r]); }
            if kind[r] == 1 { consider(3, costs[3] + best[l] + best[left[r] as usize]); }
            if kind[l] == 1 && kind[r] == 1 { consider(4, costs[4] + best[left[l] as usize] + best[left[r] as usize]); }
        }
    }
    if best[0] == i64::MAX / 4 { return -1; }
    let mut mapping = [-3i64; MAX_N]; for i in 0..n { if kind[i] == 0 { mapping[i] = -1; } }
    let mut stack = [0usize; 2 * MAX_N]; let mut top = 0usize; if kind[0] != 0 { stack[top] = 0; top += 1; }
    while top > 0 { top -= 1; let node = stack[top]; let p = choice[node]; mapping[node] = p as i64; let l = left[node] as usize;
        if p == 0 { stack[top] = l; top += 1; }
        else if p == 1 { stack[top] = l; top += 1; stack[top] = right[node] as usize; top += 1; }
        else if p == 2 { mapping[l] = -2; stack[top] = left[l] as usize; top += 1; stack[top] = right[node] as usize; top += 1; }
        else if p == 3 { let r = right[node] as usize; mapping[r] = -2; stack[top] = l; top += 1; stack[top] = left[r] as usize; top += 1; }
        else { let r = right[node] as usize; mapping[l] = -2; mapping[r] = -2; stack[top] = left[l] as usize; top += 1; stack[top] = left[r] as usize; top += 1; }
    }
    let bytes = 8 * (n + 1); if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT]; put_i64(&mut staged, 0, best[0]); for i in 0..n { put_i64(&mut staged, 8 * (i + 1), mapping[i]); }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes); } bytes as i64
}
