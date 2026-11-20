//! Independently authored draft; not compiled or run.
#[derive(Clone, Copy)]
struct State { next: [i32; 256], link: i32, length: usize, paths: i64 }
const EMPTY: State = State { next: [-1; 256], link: -1, length: 0, paths: 0 };

#[no_mangle]
pub unsafe extern "C" fn suffix_automaton_kth_distinct_substring(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=259).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (raw_n, mut k) = (values[0], values[1]);
    if !(1..=256).contains(&raw_n) || length != raw_n as usize + 2 || k < 1
        || values[2..].iter().any(|v| !(0..=255).contains(v)) { return -1; }
    let n = raw_n as usize;
    let mut states = [EMPTY; 512];
    let (mut count, mut last) = (1usize, 0usize);
    for &byte in &values[2..] {
        let symbol = byte as usize;
        let current = count; count += 1;
        states[current].length = states[last].length + 1;
        let mut p = last as i32;
        while p >= 0 && states[p as usize].next[symbol] < 0 {
            states[p as usize].next[symbol] = current as i32;
            p = states[p as usize].link;
        }
        if p < 0 { states[current].link = 0; }
        else {
            let q = states[p as usize].next[symbol] as usize;
            if states[p as usize].length + 1 == states[q].length {
                states[current].link = q as i32;
            } else {
                let clone = count; count += 1;
                states[clone] = states[q];
                states[clone].length = states[p as usize].length + 1;
                while p >= 0 && states[p as usize].next[symbol] == q as i32 {
                    states[p as usize].next[symbol] = clone as i32;
                    p = states[p as usize].link;
                }
                states[q].link = clone as i32;
                states[current].link = clone as i32;
            }
        }
        last = current;
    }
    let mut buckets = [0usize; 257];
    let mut order = [0usize; 512];
    for state in &states[..count] { buckets[state.length] += 1; }
    for i in 1..=n { buckets[i] += buckets[i - 1]; }
    for i in (0..count).rev() {
        let len = states[i].length;
        buckets[len] -= 1;
        order[buckets[len]] = i;
    }
    for &state in order[..count].iter().rev() {
        let mut paths = 0;
        for &next in &states[state].next {
            if next >= 0 { paths += 1 + states[next as usize].paths; }
        }
        states[state].paths = paths;
    }
    if k > states[0].paths { return -1; }
    let mut result = [0u8; 256];
    let (mut used, mut state) = (0usize, 0usize);
    loop {
        let mut chosen = None;
        for (symbol, &next) in states[state].next.iter().enumerate() {
            if next < 0 { continue; }
            let group = 1 + states[next as usize].paths;
            if k > group { k -= group; } else { chosen = Some((symbol, next as usize)); break; }
        }
        let Some((symbol, next)) = chosen else { return -1; };
        result[used] = symbol as u8; used += 1; state = next;
        if k == 1 { break; }
        k -= 1;
    }
    if output.is_null() || capacity < used { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(result.as_ptr(), output, used); }
    used as i64
}
