/// Return the greatest sum of a length-k window containing pairwise distinct values.
#[no_mangle]
pub extern "C" fn maximum_sum_of_distinct_subarrays_with_length_k(values: *const i64, length: usize) -> i64 {
    const INVALID: i64 = i64::MIN;
    const MAX_N: usize = 8192;
    const CAPACITY: usize = 16384;
    if values.is_null() || !(3..=MAX_N + 2).contains(&length) {
        return INVALID;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (n_value, k_value) = (values[0], values[1]);
    if !(1..=MAX_N as i64).contains(&n_value) || k_value < 1 || k_value > n_value
        || length != n_value as usize + 2
    {
        return INVALID;
    }
    let (n, k) = (n_value as usize, k_value as usize);
    let mut keys = [0i32; CAPACITY];
    let mut last_plus_one = [0i32; CAPACITY];
    let mut current_sum = 0i64;
    let mut maximum_sum = 0i64;
    let mut distinct_start = 0usize;
    for i in 0..n {
        let input = values[i + 2];
        if input < i32::MIN as i64 || input > i32::MAX as i64 {
            return INVALID;
        }
        let value = input as i32;
        if i < k { current_sum += i64::from(value); }
        else {
            current_sum -= values[i - k + 2];
            current_sum += i64::from(value);
        }
        let mut slot = ((input + 2_147_483_648) % CAPACITY as i64) as usize;
        while last_plus_one[slot] != 0 && keys[slot] != value { slot = (slot + 1) & (CAPACITY - 1); }
        if last_plus_one[slot] != 0 {
            let previous = (last_plus_one[slot] - 1) as usize;
            if previous >= distinct_start { distinct_start = previous + 1; }
        } else { keys[slot] = value; }
        last_plus_one[slot] = (i + 1) as i32;
        if i + 1 >= k {
            let start = i + 1 - k;
            if start >= distinct_start && current_sum > maximum_sum { maximum_sum = current_sum; }
        }
    }
    maximum_sum
}
