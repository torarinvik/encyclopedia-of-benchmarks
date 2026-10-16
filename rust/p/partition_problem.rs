/// Equal-sum two-way partition using bottom-up subset-sum reachability.
const MAX_ITEMS: usize = 16;
const MAX_TOTAL: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn partition_problem(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_ITEMS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut total = 0_i64;
    for &value in values {
        if value < 0 || value > 256 || total > MAX_TOTAL as i64 - value { return -1; }
        total += value;
    }
    if total & 1 != 0 { return 0; }
    let target = (total / 2) as usize;
    let mut reachable = [false; MAX_TOTAL + 1];
    reachable[0] = true;
    for &raw_value in values {
        let value = raw_value as usize;
        if value <= target {
            for sum in (value..=target).rev() {
                if reachable[sum - value] { reachable[sum] = true; }
            }
        }
    }
    i64::from(reachable[target])
}
