use std::cmp::Reverse;
use std::collections::BinaryHeap;

fn entry(mask: u8, choices: &[(i32, usize, i32)]) -> (i32, u32, u8) {
    let score = choices.iter().enumerate().filter(|(i, _)| mask & (1 << *i) != 0)
        .map(|(_, choice)| choice.0 * choice.0).sum();
    (score, mask.count_ones(), mask)
}

#[no_mangle]
pub unsafe extern "C" fn multiprobe_lsh_probe_sequence(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(4..=7).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=4).contains(&values[0]) || !(1..=1000).contains(&values[1]) { return -1; }
    let m = values[0] as usize;
    let width = values[1] as i32;
    if length != 3+m || values[2] < 0 || values[2] >= 3i64.pow(m as u32)
        || values[3..].iter().any(|x| *x < 0 || *x > width as i64) { return -1; }
    let count = values[2] as usize;
    let mut choices = Vec::with_capacity(2*m);
    for i in 0..m {
        let low = values[3+i] as i32;
        choices.push((low, i, -1)); choices.push((width-low, i, 1));
    }
    choices.sort_unstable();
    let mut heap = BinaryHeap::new();
    heap.push(Reverse(entry(1, &choices)));
    let mut result = Vec::with_capacity(count);
    while result.len() < count {
        let Reverse((_, _, mask)) = heap.pop().unwrap();
        let top = 7 - mask.leading_zeros() as usize;
        if top+1 < 2*m {
            heap.push(Reverse(entry((mask ^ (1 << top)) | (1 << (top+1)), &choices)));
            heap.push(Reverse(entry(mask | (1 << (top+1)), &choices)));
        }
        let mut seen = 0u8;
        let mut valid = true;
        for (i, choice) in choices.iter().enumerate() {
            if mask & (1 << i) == 0 { continue; }
            let bit = 1 << choice.1;
            if seen & bit != 0 { valid = false; break; }
            seen |= bit;
        }
        if valid { result.push(mask); }
    }
    if output.is_null() || capacity < count { return -2; }
    std::ptr::copy_nonoverlapping(result.as_ptr(), output, count);
    count as i64
}
