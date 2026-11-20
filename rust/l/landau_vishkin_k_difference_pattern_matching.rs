const MAX_PATTERN: usize = 16;
const MAX_TEXT: usize = 32;
const MAX_ERRORS: usize = 2;
const MAX_VALID_INPUT: usize = 3 + MAX_PATTERN + MAX_TEXT;
const MAX_PARSEABLE_INPUT: usize = MAX_VALID_INPUT + 1;
const DIAGONALS: usize = MAX_TEXT + MAX_ERRORS + 3;
const COSTS: usize = MAX_ERRORS + 2;

fn diagonal_slot(diagonal: isize) -> usize {
    (diagonal + MAX_ERRORS as isize + 1) as usize
}

#[no_mangle]
pub unsafe extern "C" fn landau_vishkin_k_difference_pattern_matching(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT {
        return -1;
    }
    let raw_m = *input;
    let raw_n = *input.add(1);
    let raw_k = *input.add(2);
    if raw_m < 1 || raw_m > MAX_PATTERN as i64 || raw_n < 0 || raw_n > MAX_TEXT as i64
        || raw_k < 0 || raw_k > MAX_ERRORS as i64 || raw_k >= raw_m
    {
        return -1;
    }
    let m = raw_m as usize;
    let n = raw_n as usize;
    let k = raw_k as usize;
    if length != 3 + m + n {
        return -1;
    }
    let pattern = std::slice::from_raw_parts(input.add(3), m);
    let text = std::slice::from_raw_parts(input.add(3 + m), n);
    if pattern.iter().chain(text.iter()).any(|&symbol| !(0..=3).contains(&symbol)) {
        return -1;
    }
    if output.is_null() || capacity < n {
        return -2;
    }

    let mut frontier = [[-1i64; COSTS]; DIAGONALS];
    for diagonal in -(k as isize + 1)..0 {
        let magnitude = (-diagonal) as usize;
        let slot = diagonal_slot(diagonal);
        frontier[slot][magnitude] = magnitude as i64 - 1;
        frontier[slot][magnitude - 1] = magnitude as i64 - 2;
    }
    let mut staged = [0u8; MAX_TEXT];
    for errors in 0..=k {
        for diagonal in -(errors as isize)..=n as isize {
            let slot = diagonal_slot(diagonal);
            let mut row = (frontier[slot][errors] + 1)
                .max(frontier[slot - 1][errors])
                .max(frontier[slot + 1][errors] + 1)
                .min(raw_m);
            while row < raw_m {
                let text_index = row + diagonal as i64;
                if text_index < 0 || text_index >= raw_n
                    || pattern[row as usize] != text[text_index as usize]
                {
                    break;
                }
                row += 1;
            }
            frontier[slot][errors + 1] = row;
            if row == raw_m {
                let endpoint = diagonal + raw_m as isize;
                if endpoint >= 1 && endpoint <= raw_n as isize {
                    staged[(endpoint - 1) as usize] = 1;
                }
            }
        }
    }
    std::slice::from_raw_parts_mut(output, n).copy_from_slice(&staged[..n]);
    n as i64
}
