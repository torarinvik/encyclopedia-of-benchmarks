const MAX_JOBS: usize = 32;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_JOBS + 1;
const MAX_PROFIT: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn job_sequencing(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    if !(1..=MAX_JOBS as i64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != 1 + 3 * n { return -1; }
    let mut seen = [false; 128];
    let mut previous_profit = MAX_PROFIT + 1;
    for index in 0..n {
        let base = 1 + 3 * index;
        let id = values[base]; let deadline = values[base + 1]; let profit = values[base + 2];
        let letter = (65..=90).contains(&id) || (97..=122).contains(&id);
        if !letter || seen[id as usize] || deadline < 1 || deadline > n as i64 || profit < 1 || profit > MAX_PROFIT || profit >= previous_profit { return -1; }
        seen[id as usize] = true; previous_profit = profit;
    }
    let mut slots = [0u8; MAX_JOBS];
    let mut total_profit = 0_i64;
    for index in 0..n {
        let base = 1 + 3 * index;
        let deadline = values[base + 1] as usize;
        for remaining in (1..=deadline).rev() {
            let slot = remaining - 1;
            if slots[slot] == 0 { slots[slot] = values[base] as u8; total_profit += values[base + 2]; break; }
        }
    }
    let count = slots[..n].iter().filter(|&&id| id != 0).count();
    let required = 9 + count;
    if output.is_null() || capacity < required { return -2; }
    let result = core::slice::from_raw_parts_mut(output, capacity);
    result[0] = count as u8; result[1..9].copy_from_slice(&(total_profit as u64).to_le_bytes());
    let mut written = 9; for &id in &slots[..n] { if id != 0 { result[written] = id; written += 1; } }
    required as i64
}
