const MAX_TASKS: usize = 8;
const MAX_INPUT: usize = 17;
const MAX_OUTPUT_BYTES: usize = 80;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn rate_monotonic_scheduling(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if count_value < 1 || count_value > MAX_TASKS as i64 ||
        length != 1 + 2 * count_value as usize { return -1; }
    let count = count_value as usize;
    let mut execution = [0i64; MAX_TASKS];
    let mut period = [0i64; MAX_TASKS];
    let mut order = [0usize; MAX_TASKS];
    let mut response = [-1i64; MAX_TASKS];
    for task in 0..count {
        execution[task] = values[1 + 2 * task];
        period[task] = values[2 + 2 * task];
        if !(1..=16).contains(&execution[task]) || !(1..=32).contains(&period[task]) { return -1; }
        order[task] = task;
    }
    for index in 1..count {
        let key = order[index];
        let mut position = index;
        while position > 0 && (period[order[position - 1]] > period[key] ||
            period[order[position - 1]] == period[key] && order[position - 1] > key) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }

    let mut schedulable = 1i64;
    let mut failed_task = -1i64;
    for rank in 0..count {
        let target = order[rank];
        let mut remaining_target = execution[target];
        let mut active = [0i64; MAX_TASKS];
        let mut elapsed = 0i64;
        while remaining_target > 0 && elapsed < period[target] {
            for higher_rank in 0..rank {
                let higher = order[higher_rank];
                if elapsed % period[higher] == 0 { active[higher] += execution[higher]; }
            }
            let mut selected = None;
            for higher_rank in 0..rank {
                let higher = order[higher_rank];
                if active[higher] > 0 { selected = Some(higher); break; }
            }
            if let Some(higher) = selected { active[higher] -= 1; }
            else { remaining_target -= 1; }
            elapsed += 1;
        }
        if remaining_target > 0 {
            schedulable = 0;
            failed_task = target as i64;
            break;
        }
        response[target] = elapsed;
    }

    let output_bytes = 8 * (count + 2);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    store_i64_le(staged.as_mut_ptr(), 0, schedulable);
    store_i64_le(staged.as_mut_ptr(), 8, failed_task);
    for task in 0..count { store_i64_le(staged.as_mut_ptr(), 8 * (task + 2), response[task]); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
