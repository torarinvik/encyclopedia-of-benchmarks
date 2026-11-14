// Uncompiled and unexecuted next-occurrence automaton draft.
#[no_mangle]
pub unsafe extern "C" fn subsequence_automaton(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=354).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=64).contains(&values[0]) || !(0..=32).contains(&values[1]) { return -1; }
    let (n, queries) = (values[0] as usize, values[1] as usize);
    if length < 2+n || values[2..2+n].iter().any(|&x| !(0..=3).contains(&x)) { return -1; }
    let mut next = [[n; 4]; 65];
    for i in (0..n).rev() {
        next[i] = next[i+1];
        next[i][values[2+i] as usize] = i;
    }
    let (mut position, mut total, mut answer) = (2+n, 0usize, 0i64);
    for query in 0..queries {
        if position == length || !(0..=256).contains(&values[position]) { return -1; }
        let count = values[position] as usize;
        position += 1;
        if count > 256-total || count > length-position { return -1; }
        let mut cursor = 0;
        let mut matches = true;
        for &symbol in &values[position..position+count] {
            if !(0..=3).contains(&symbol) { return -1; }
            if matches {
                let found = next[cursor][symbol as usize];
                if found == n { matches = false; } else { cursor = found+1; }
            }
        }
        if matches { answer += (query+1) as i64; }
        position += count; total += count;
    }
    if position == length { answer } else { -1 }
}
