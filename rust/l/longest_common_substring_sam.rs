#[derive(Clone, Copy)]
struct State { next: [i32; 95], link: i32, len: usize }
const EMPTY: State = State { next: [-1; 95], link: -1, len: 0 };

#[no_mangle]
pub unsafe extern "C" fn longest_common_substring_sam(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=515).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=256).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length < n+2 || !(0..=256).contains(&values[n+1]) { return -1; }
    let m = values[n+1] as usize;
    if length != n+m+2 || values[1..n+1].iter().any(|x| !(32..=126).contains(x)) || values[n+2..].iter().any(|x| !(32..=126).contains(x)) { return -1; }
    let mut states = [EMPTY; 513]; let mut size = 1usize; let mut last = 0usize;
    for &raw in &values[1..n+1] {
        let symbol = (raw-32) as usize; let current = size; size += 1;
        states[current].len = states[last].len+1; let mut p = last as i32;
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
    let (mut state, mut matched, mut best) = (0usize, 0usize, 0usize);
    for &raw in &values[n+2..] {
        let symbol = (raw-32) as usize;
        while state != 0 && states[state].next[symbol] < 0 { state = states[state].link as usize; matched = states[state].len; }
        let next = states[state].next[symbol];
        if next < 0 { state = 0; matched = 0; }
        else { state = next as usize; matched += 1; best = best.max(matched); }
    }
    best as i64
}
