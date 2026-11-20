const MAX_SEQUENCE_LENGTH: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 122;

fn pair_input_index(n: usize, left: usize, right: usize) -> usize {
    let preceding = left * (2 * n - left - 1) / 2;
    1 + preceding + (right - left - 1)
}

#[no_mangle]
pub unsafe extern "C" fn rna_pair_activity_partition_function(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) {
        return -1;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    if values[0] < 0 || values[0] as usize > MAX_SEQUENCE_LENGTH {
        return -1;
    }
    let n = values[0] as usize;
    let expected_length = if n == 0 { 1 } else { 1 + n * (n - 1) / 2 };
    if length != expected_length || values[1..].iter().any(|&activity| !(0..=3).contains(&activity)) {
        return -1;
    }
    if n == 0 {
        return 1;
    }

    let mut table = [[0_i64; MAX_SEQUENCE_LENGTH]; MAX_SEQUENCE_LENGTH];
    for span in 1..=n {
        for left in 0..=n - span {
            let right = left + span - 1;
            let mut total = if left == right { 1 } else { table[left][right - 1] };
            for partner in left..right {
                let activity = values[pair_input_index(n, partner, right)];
                let before = if partner == left { 1 } else { table[left][partner - 1] };
                let inside = if partner + 1 >= right { 1 } else { table[partner + 1][right - 1] };
                total += before * inside * activity;
            }
            table[left][right] = total;
        }
    }
    table[0][n - 1]
}
