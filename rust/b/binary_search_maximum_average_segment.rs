const MAX_N: usize = 32;
const MAX_INPUT: usize = 35;
const INVALID_RESULT: i64 = -1_000_001;

fn feasible(input: &[i64], n: usize, minimum_length: usize, threshold: i64) -> bool {
    let mut prefix = [0_i64; MAX_N + 1];
    for index in 0..n {
        prefix[index + 1] = prefix[index] + 1000 * input[index + 2] - threshold;
    }
    let mut minimum_prefix = i64::MAX;
    for end in minimum_length..=n {
        let eligible_start = end - minimum_length;
        minimum_prefix = minimum_prefix.min(prefix[eligible_start]);
        if prefix[end] >= minimum_prefix {
            return true;
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn binary_search_maximum_average_segment(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT).contains(&length) {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, minimum_value) = (values[0], values[1]);
    if !(1..=MAX_N as i64).contains(&n_value)
        || minimum_value < 1
        || minimum_value > n_value
        || length != n_value as usize + 2
    {
        return INVALID_RESULT;
    }
    let n = n_value as usize;
    if values[2..].iter().any(|&value| !(-1000..=1000).contains(&value)) {
        return INVALID_RESULT;
    }

    let mut low = -1_000_000_i64;
    let mut high = 1_000_001_i64;
    while high - low > 1 {
        let middle = low + (high - low) / 2;
        if feasible(values, n, minimum_value as usize, middle) {
            low = middle;
        } else {
            high = middle;
        }
    }
    low
}
