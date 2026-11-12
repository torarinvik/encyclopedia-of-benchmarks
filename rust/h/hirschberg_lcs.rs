const MAX_SEQUENCE_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 132;

struct HirschbergState {
    forward: [i32; MAX_SEQUENCE_LENGTH + 1],
    backward: [i32; MAX_SEQUENCE_LENGTH + 1],
    result: [u8; MAX_SEQUENCE_LENGTH],
    result_length: usize,
}

fn lcs_row(a: &[i64], a0: usize, a1: usize, b: &[i64], b0: usize, b1: usize,
           reverse_a: bool, reverse_b: bool, row: &mut [i32; MAX_SEQUENCE_LENGTH + 1]) {
    let width = b1 - b0;
    row[..=width].fill(0);
    for i in 0..a1 - a0 {
        let av = if reverse_a { a[a1 - 1 - i] } else { a[a0 + i] };
        let mut diagonal = 0;
        for j in 1..=width {
            let above = row[j];
            let bv = if reverse_b { b[b1 - j] } else { b[b0 + j - 1] };
            if av == bv {
                row[j] = diagonal + 1;
            } else if row[j - 1] > row[j] {
                row[j] = row[j - 1];
            }
            diagonal = above;
        }
    }
}

fn recover_lcs(a: &[i64], a0: usize, a1: usize, b: &[i64], b0: usize, b1: usize,
               state: &mut HirschbergState) {
    let a_length = a1 - a0;
    let b_length = b1 - b0;
    if a_length == 0 || b_length == 0 { return; }
    if a_length == 1 {
        for j in b0..b1 {
            if a[a0] == b[j] {
                state.result[state.result_length] = a[a0] as u8;
                state.result_length += 1;
                return;
            }
        }
        return;
    }

    let middle = a0 + a_length / 2;
    lcs_row(a, a0, middle, b, b0, b1, false, false, &mut state.forward);
    lcs_row(a, middle, a1, b, b0, b1, true, true, &mut state.backward);
    let mut split = 0;
    let mut best_score = -1;
    for j in 0..=b_length {
        let score = state.forward[j] + state.backward[b_length - j];
        if score > best_score {
            best_score = score;
            split = j;
        }
    }
    recover_lcs(a, a0, middle, b, b0, b0 + split, state);
    recover_lcs(a, middle, a1, b, b0 + split, b1, state);
}

#[no_mangle]
pub unsafe extern "C" fn hirschberg_lcs(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_SEQUENCE_LENGTH as i64).contains(&values[0])
        || !(0..=MAX_SEQUENCE_LENGTH as i64).contains(&values[1]) { return -1; }
    let first_length = values[0] as usize;
    let second_length = values[1] as usize;
    if length != 2 + first_length + second_length { return -1; }
    let first = &values[2..2 + first_length];
    let second = &values[2 + first_length..];
    if first.iter().chain(second).any(|&value| !(0..=127).contains(&value)) { return -1; }

    let (a, b) = if first.len() < second.len() { (second, first) } else { (first, second) };
    let mut state = HirschbergState {
        forward: [0; MAX_SEQUENCE_LENGTH + 1],
        backward: [0; MAX_SEQUENCE_LENGTH + 1],
        result: [0; MAX_SEQUENCE_LENGTH],
        result_length: 0,
    };
    recover_lcs(a, 0, a.len(), b, 0, b.len(), &mut state);
    if output.is_null() || capacity < state.result_length { return -2; }
    std::ptr::copy_nonoverlapping(state.result.as_ptr(), output, state.result_length);
    state.result_length as i64
}
