const MAX_LENGTH: i64 = 8;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2 * MAX_LENGTH as usize + 3;
const MEMO_SIZE: usize = 9 * 9 * 9;

fn scramble_rec(values: &[i64], base1: usize, base2: usize, start1: usize, start2: usize,
                span: usize, memo: &mut [i64; MEMO_SIZE]) -> i64 {
    let slot = (start1 * 9 + start2) * 9 + span;
    if memo[slot] >= 0 { return memo[slot]; }

    let mut same = true;
    for offset in 0..span {
        if values[base1 + start1 + offset] != values[base2 + start2 + offset] {
            same = false;
            break;
        }
    }
    if same {
        memo[slot] = 1;
        return 1;
    }

    let mut counts = [0i64; 26];
    for offset in 0..span {
        counts[(values[base1 + start1 + offset] - 97) as usize] += 1;
        counts[(values[base2 + start2 + offset] - 97) as usize] -= 1;
    }
    if counts.iter().any(|count| *count != 0) {
        memo[slot] = 0;
        return 0;
    }

    for split in 1..span {
        if scramble_rec(values, base1, base2, start1, start2, split, memo) != 0 &&
            scramble_rec(values, base1, base2, start1 + split, start2 + split, span - split, memo) != 0 {
            memo[slot] = 1;
            return 1;
        }
        if scramble_rec(values, base1, base2, start1, start2 + span - split, split, memo) != 0 &&
            scramble_rec(values, base1, base2, start1 + split, start2, span - split, memo) != 0 {
            memo[slot] = 1;
            return 1;
        }
    }
    memo[slot] = 0;
    0
}

#[no_mangle]
pub unsafe extern "C" fn scramble_strings(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let n_value = input[0];
    if n_value < 0 || n_value > MAX_LENGTH { return -1; }
    let n = n_value as usize;
    if length != 2 * n + 1 { return -1; }
    if input[1..].iter().any(|value| !(97..=122).contains(value)) { return -1; }

    let mut memo = [-1i64; MEMO_SIZE];
    scramble_rec(input, 1, 1 + n, 0, 0, n, &mut memo)
}
