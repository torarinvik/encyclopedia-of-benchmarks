const MAX_VARS: usize = 12;
const MAX_CLAUSES: usize = 32;
const MAX_INPUT: usize = 98;
const MAX_OUTPUT: usize = 96;

fn put(out: &mut [u8], at: usize, value: i64) { out[at..at + 8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn random_planted_3sat_majority_vote(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(3..=MAX_VARS as i64).contains(&values[0]) || values[1] < 0 || values[1] > MAX_CLAUSES as i64 { return -1; }
    let n = values[0] as usize; let m = values[1] as usize;
    if length != 2 + 3 * m { return -1; }
    let mut positive = [0i32; MAX_VARS]; let mut negative = [0i32; MAX_VARS];
    for c in 0..m {
        let mut seen = [false; MAX_VARS];
        for j in 0..3 {
            let lit = values[2 + 3 * c + j];
            if lit == 0 || lit < -(n as i64) || lit > n as i64 { return -1; }
            let v = lit.unsigned_abs() as usize - 1;
            if seen[v] { return -1; }
            seen[v] = true;
            if lit > 0 { positive[v] += 1; } else { negative[v] += 1; }
        }
    }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    for v in 0..n { put(&mut staged, 8 * v, if positive[v] > negative[v] { 1 } else { -1 }); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
