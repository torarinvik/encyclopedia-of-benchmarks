const MAX_VALID_INPUT_LENGTH: usize = 64;
const MAX_TOTAL_SUM: i64 = 4096;

#[no_mangle]
pub unsafe extern "C" fn minimum_sum_partition(input: *const i64, length: usize) -> i64 {
    if length > MAX_VALID_INPUT_LENGTH || (input.is_null() && length != 0) { return -1; }

    let mut total = 0_i64;
    for index in 0..length {
        let value = unsafe { *input.add(index) };
        if value < 0 || value > MAX_TOTAL_SUM || total > MAX_TOTAL_SUM - value { return -1; }
        total += value;
    }

    let target = (total / 2) as usize;
    let mut reachable = [false; MAX_TOTAL_SUM as usize / 2 + 1];
    reachable[0] = true;
    let mut closest = 0_usize;
    for index in 0..length {
        let value = unsafe { *input.add(index) } as usize;
        for sum in (1..=target).rev() {
            if value <= sum && reachable[sum - value] { reachable[sum] = true; }
            if reachable[sum] && sum > closest { closest = sum; }
        }
    }
    total - 2 * closest as i64
}
