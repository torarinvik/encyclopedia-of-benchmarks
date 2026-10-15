/// Find the cycle entrance induced by the duplicate value.
#[no_mangle]
pub extern "C" fn find_duplicate_number(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > 100001 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let maximum_value = length - 1;
    if values.iter().any(|&value| value < 1 || value as u64 > maximum_value as u64) {
        return -1;
    }

    let mut slow = values[0] as usize;
    let mut fast = slow;
    loop {
        slow = values[slow] as usize;
        fast = values[values[fast] as usize] as usize;
        if slow == fast { break; }
    }

    slow = values[0] as usize;
    while slow != fast {
        slow = values[slow] as usize;
        fast = values[fast] as usize;
    }
    slow as i64
}
