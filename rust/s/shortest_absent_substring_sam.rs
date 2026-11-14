#[derive(Clone, Copy)]
struct State { next: [i32; 4], link: i32, len: usize }
const EMPTY: State = State { next: [-1; 4], link: -1, len: 0 };

#[no_mangle]
pub unsafe extern "C" fn shortest_absent_substring_sam(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(2..=66).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=4).contains(&values[0]) || !(0..=64).contains(&values[1]) { return -1; }
    let alphabet = values[0] as usize; let n = values[1] as usize;
    if length != 2+n || values[2..].iter().any(|&x| x < 0 || x >= alphabet as i64) { return -1; }
    let mut states = [EMPTY; 129];
    let mut size = 1usize; let mut last = 0usize;
    for &symbol in &values[2..] {
        let symbol = symbol as usize; let current = size; size += 1;
        states[current].len = states[last].len+1;
        let mut p = last as i32;
        while p >= 0 && states[p as usize].next[symbol] < 0 {
            states[p as usize].next[symbol] = current as i32; p = states[p as usize].link;
        }
        if p < 0 { states[current].link = 0; }
        else {
            let q = states[p as usize].next[symbol] as usize;
            if states[p as usize].len+1 == states[q].len { states[current].link = q as i32; }
            else {
                let clone = size; size += 1; states[clone] = states[q]; states[clone].len = states[p as usize].len+1;
                while p >= 0 && states[p as usize].next[symbol] == q as i32 {
                    states[p as usize].next[symbol] = clone as i32; p = states[p as usize].link;
                }
                states[q].link = clone as i32; states[current].link = clone as i32;
            }
        }
        last = current;
    }
    let mut counts = [0usize;65]; let mut order = [0usize;129]; let mut dp = [0usize;129];
    for state in &states[..size] { counts[state.len] += 1; }
    for i in 1..=n { counts[i] += counts[i-1]; }
    for s in (0..size).rev() { counts[states[s].len] -= 1; order[counts[states[s].len]] = s; }
    for &s in order[..size].iter().rev() {
        dp[s] = (0..alphabet).map(|a| { let c = states[s].next[a]; if c < 0 { 1 } else { 1+dp[c as usize] } }).min().unwrap();
    }
    let mut result = [0u8;6]; let mut count = 0; let mut state = 0i32;
    while state >= 0 {
        let s = state as usize;
        for a in 0..alphabet {
            let child = states[s].next[a];
            if (child < 0 && dp[s] == 1) || (child >= 0 && dp[s] == 1+dp[child as usize]) {
                result[count] = a as u8; count += 1; state = child; break;
            }
        }
    }
    if output.is_null() || capacity < count { return -2; }
    std::ptr::copy_nonoverlapping(result.as_ptr(), output, count);
    count as i64
}
