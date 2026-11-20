//! Uncompiled suffix-automaton minimum-rotation draft.
#[derive(Clone, Copy)]
struct State { next: [i32; 256], link: i32, length: usize }
const EMPTY: State = State { next: [-1; 256], link: -1, length: 0 };

#[no_mangle]
pub unsafe extern "C" fn suffix_automaton_minimum_rotation(
    input: *const i64, length: usize, output: *mut u8, capacity: usize
) -> i64 {
    if input.is_null() || !(2..=258).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let raw_n = values[0];
    if !(1..=256).contains(&raw_n) || length != raw_n as usize + 1 { return -1; }
    if values[1..].iter().any(|v| !(0..=255).contains(v)) { return -1; }
    let n = raw_n as usize;
    if output.is_null() || capacity < n { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, n) };
    let mut states = [EMPTY; 1024];
    let (mut count, mut last) = (1usize, 0usize);
    for i in 0..2*n {
        let symbol = values[1+i%n] as usize;
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
    let mut state = 0usize;
    for byte in output {
        let symbol = states[state].next.iter().position(|&next| next >= 0).unwrap();
        *byte = symbol as u8;
        state = states[state].next[symbol] as usize;
    }
    raw_n
}
