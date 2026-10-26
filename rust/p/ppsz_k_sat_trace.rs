const MAX_N: usize = 8;
const MAX_CLAUSES: usize = 12;
const MAX_INPUT: usize = 54;
const MAX_OUTPUT: usize = 72;
fn put(out: &mut [u8; MAX_OUTPUT], at: usize, value: i64) { out[at..at + 8].copy_from_slice(&value.to_le_bytes()); }
fn fixed_mask(mut mask: usize, assigned: &[i8; MAX_N], n: usize) -> usize {
    for i in 0..n { if assigned[i] >= 0 { if assigned[i] == 1 { mask |= 1 << i; } else { mask &= !(1 << i); } } }
    mask
}
fn clause_true(clause: &[i64; 3], mask: usize) -> bool {
    for &literal in clause { let bit = (mask >> (literal.unsigned_abs() as usize - 1)) & 1;
        if (literal > 0 && bit == 1) || (literal < 0 && bit == 0) { return true; } }
    false
}
fn selected_true(clauses: &[[i64; 3]; MAX_CLAUSES], m: usize, subset: usize, mask: usize) -> bool {
    for i in 0..m { if (subset & (1 << i)) != 0 && !clause_true(&clauses[i], mask) { return false; } } true
}
fn current_sat(n: usize, m: usize, clauses: &[[i64; 3]; MAX_CLAUSES], assigned: &[i8; MAX_N]) -> bool {
    for mask in 0..(1 << n) { if selected_true(clauses, m, (1 << m) - 1, fixed_mask(mask, assigned, n)) { return true; } } false
}
fn find_force(n: usize, m: usize, clauses: &[[i64; 3]; MAX_CLAUSES], assigned: &[i8; MAX_N]) -> Option<(usize, i8)> {
    if !current_sat(n, m, clauses, assigned) { return None; }
    let mut threshold = 0usize; while (1 << (threshold + 1)) <= n { threshold += 1; }
    let mut implied = [-1i8; MAX_N];
    for subset in 1..(1 << m) {
        if subset.count_ones() as usize > threshold { continue; }
        let mut zero = [false; MAX_N]; let mut one = [false; MAX_N];
        for mask in 0..(1 << n) {
            let full = fixed_mask(mask, assigned, n);
            if selected_true(clauses, m, subset, full) { for x in 0..n { if assigned[x] < 0 { if (full >> x) & 1 == 1 { one[x] = true; } else { zero[x] = true; } } } }
        }
        for x in 0..n { if assigned[x] < 0 && zero[x] != one[x] && implied[x] < 0 { implied[x] = if one[x] { 1 } else { 0 }; } }
    }
    for x in 0..n { if implied[x] >= 0 { return Some((x, implied[x])); } } None
}

#[no_mangle]
pub extern "C" fn ppsz_k_sat_trace(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let v = unsafe { std::slice::from_raw_parts(input, length) };
    if v[0] < 3 || v[0] > MAX_N as i64 || v[1] < 0 || v[1] > MAX_CLAUSES as i64 { return -1; }
    let n = v[0] as usize; let m = v[1] as usize; if length != 2 + 3 * m + 2 * n { return -1; }
    let mut clauses = [[0i64; 3]; MAX_CLAUSES];
    for i in 0..m { let mut seen = [false; MAX_N]; for j in 0..3 { let lit = v[2 + 3 * i + j]; if lit == 0 || lit < -(n as i64) || lit > n as i64 { return -1; }
        let x = lit.unsigned_abs() as usize - 1; if seen[x] { return -1; } seen[x] = true; clauses[i][j] = lit; } }
    let start = 2 + 3 * m; let mut order = [0usize; MAX_N]; let mut beta = [0i8; MAX_N]; let mut seen = [false; MAX_N]; let mut assigned = [-1i8; MAX_N];
    for i in 0..n { let x = v[start + i]; if x < 0 || x >= n as i64 || seen[x as usize] { return -1; } order[i] = x as usize; seen[x as usize] = true; }
    for i in 0..n { let bit = v[start + n + i]; if bit != 0 && bit != 1 { return -1; } beta[i] = bit as i8; }
    for step in 0..n { while let Some((x, bit)) = find_force(n, m, &clauses, &assigned) { assigned[x] = bit; }
        let x = order[step]; if assigned[x] < 0 { assigned[x] = beta[x]; } }
    let mut mask = 0usize; for i in 0..n { if assigned[i] == 1 { mask |= 1 << i; } }
    let verdict = if selected_true(&clauses, m, (1 << m) - 1, mask) { 1 } else { 0 };
    let bytes = 8 * (n + 1); if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT]; put(&mut staged, 0, verdict);
    for i in 0..n { put(&mut staged, 8 * (i + 1), assigned[i] as i64); }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes); } bytes as i64
}
