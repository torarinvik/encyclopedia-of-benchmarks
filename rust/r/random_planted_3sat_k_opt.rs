const MAX_VARS: usize = 12;
const MAX_CLAUSES: usize = 32;
const MAX_INPUT: usize = 98;
const MAX_OUTPUT: usize = 104;

fn put(out: &mut [u8], at: usize, value: i64) { out[at..at + 8].copy_from_slice(&value.to_le_bytes()); }
fn sat_set(clauses: &[i32; 96], m: usize, n: usize, code: u32) -> u32 {
    let mut set = 0u32;
    for c in 0..m {
        let mut satisfied = false;
        for j in 0..3 {
            let lit = clauses[3 * c + j]; let v = lit.unsigned_abs() as usize - 1;
            let truth = ((code >> (n - 1 - v)) & 1) != 0;
            if truth == (lit > 0) { satisfied = true; }
        }
        if satisfied { set |= 1u32 << c; }
    }
    set
}

#[no_mangle]
pub unsafe extern "C" fn random_planted_3sat_k_opt(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(3..=MAX_VARS as i64).contains(&values[0]) || values[1] < 0 || values[1] > MAX_CLAUSES as i64 { return -1; }
    let n = values[0] as usize; let m = values[1] as usize;
    if length != 2 + 3 * m { return -1; }
    let mut clauses = [0i32; 96]; let mut positive = [0i32; MAX_VARS]; let mut negative = [0i32; MAX_VARS];
    for c in 0..m {
        let mut seen = [false; MAX_VARS];
        for j in 0..3 {
            let raw = values[2 + 3 * c + j];
            if raw == 0 || raw < -(n as i64) || raw > n as i64 { return -1; }
            let lit = raw as i32; let v = lit.unsigned_abs() as usize - 1;
            if seen[v] { return -1; }
            seen[v] = true; clauses[3 * c + j] = lit;
            if lit > 0 { positive[v] += 1; } else { negative[v] += 1; }
        }
    }
    let mut current = 0u32;
    for v in 0..n { if positive[v] > negative[v] { current |= 1u32 << (n - 1 - v); } }
    let full = if m == 32 { u32::MAX } else if m == 0 { 0 } else { (1u32 << m) - 1 };
    let mut k = 1usize; let status: i64;
    loop {
        let before = sat_set(&clauses, m, n, current);
        if before == full { status = 1; break; }
        let mut found = false;
        for candidate in 0..(1u32 << n) {
            let distance = (current ^ candidate).count_ones() as usize;
            if distance == 0 || distance > k { continue; }
            let after = sat_set(&clauses, m, n, candidate);
            if after != before && (after & before) == before { current = candidate; found = true; break; }
        }
        if found { continue; }
        if k == n { status = 0; break; }
        k += 1;
    }
    let bytes = 8 * (n + 1);
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT]; put(&mut staged, 0, status);
    for v in 0..n { let truth = ((current >> (n - 1 - v)) & 1) != 0; put(&mut staged, 8 * (v + 1), if truth { 1 } else { -1 }); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
