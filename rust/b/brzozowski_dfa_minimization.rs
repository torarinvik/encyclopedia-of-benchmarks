const MAX_STATES: usize = 3;
const FIRST_SUBSETS: usize = 1 << MAX_STATES;
const SECOND_SUBSETS: usize = 1 << FIRST_SUBSETS;

#[no_mangle]
pub unsafe extern "C" fn brzozowski_dfa_minimization(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=10).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n64, start64, accepting64) = (values[0], values[1], values[2]);
    if !(1..=MAX_STATES as i64).contains(&n64) || start64 < 0 || start64 >= n64
        || accepting64 < 0 || accepting64 >= (1i64 << n64) { return -1; }
    let n = n64 as usize;
    if length != 3 + 2 * n { return -1; }
    let start = start64 as usize;
    let mut transitions = [[0usize; 2]; MAX_STATES];
    for state in 0..n {
        for symbol in 0..2 {
            let target = values[3 + 2 * state + symbol];
            if target < 0 || target >= n64 { return -1; }
            transitions[state][symbol] = target as usize;
        }
    }

    let mut first_masks = [0u16; FIRST_SUBSETS];
    let mut first_delta = [[0usize; 2]; FIRST_SUBSETS];
    let mut first_final = [false; FIRST_SUBSETS];
    let mut first_id = [-1i32; FIRST_SUBSETS];
    let mut first_count = 1usize;
    first_masks[0] = accepting64 as u16;
    first_id[accepting64 as usize] = 0;
    let mut cursor = 0usize;
    while cursor < first_count {
        let subset = first_masks[cursor];
        first_final[cursor] = ((subset >> start) & 1) != 0;
        for symbol in 0..2 {
            let mut predecessor = 0u16;
            for state in 0..n {
                if subset & (1u16 << transitions[state][symbol]) != 0 {
                    predecessor |= 1u16 << state;
                }
            }
            let mask_index = predecessor as usize;
            if first_id[mask_index] < 0 {
                first_id[mask_index] = first_count as i32;
                first_masks[first_count] = predecessor;
                first_count += 1;
            }
            first_delta[cursor][symbol] = first_id[mask_index] as usize;
        }
        cursor += 1;
    }

    let mut first_accepting = 0u16;
    for state in 0..first_count {
        if first_final[state] { first_accepting |= 1u16 << state; }
    }
    let mut second_queue = [0u16; SECOND_SUBSETS];
    let mut second_seen = [false; SECOND_SUBSETS];
    let mut second_count = 1usize;
    second_queue[0] = first_accepting;
    second_seen[first_accepting as usize] = true;
    cursor = 0;
    while cursor < second_count {
        let subset = second_queue[cursor];
        for symbol in 0..2 {
            let mut predecessor = 0u16;
            for state in 0..first_count {
                if subset & (1u16 << first_delta[state][symbol]) != 0 {
                    predecessor |= 1u16 << state;
                }
            }
            let mask_index = predecessor as usize;
            if !second_seen[mask_index] {
                second_seen[mask_index] = true;
                second_queue[second_count] = predecessor;
                second_count += 1;
            }
        }
        cursor += 1;
    }
    second_count as i64
}
