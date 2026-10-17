const MAX_INPUT_LENGTH: usize = 130;
const MAX_PROCESSES: usize = 64;
const MAX_OUTPUT_BYTES: usize = 256;

fn execute(input: &[i32], order: &mut [i32; MAX_PROCESSES]) -> Result<usize, ()> {
    if input.is_empty() || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let process_count_value = input[0];
    if !(0..=MAX_PROCESSES as i32).contains(&process_count_value)
        || input.len() != 1 + 2 * process_count_value as usize { return Err(()); }
    let process_count = process_count_value as usize;

    let mut arrivals = [0i32; MAX_PROCESSES];
    let mut bursts = [0i32; MAX_PROCESSES];
    let mut completed = [false; MAX_PROCESSES];
    let mut cursor = 1;
    for index in 0..process_count {
        let arrival = input[cursor];
        let burst = input[cursor + 1];
        cursor += 2;
        if !(0..=255).contains(&arrival) || !(1..=255).contains(&burst) { return Err(()); }
        arrivals[index] = arrival;
        bursts[index] = burst;
    }

    let mut current_time = 0i32;
    let mut scheduled = 0;
    while scheduled < process_count {
        let mut best = process_count;
        for index in 0..process_count {
            if completed[index] || arrivals[index] > current_time { continue; }
            if best == process_count || bursts[index] < bursts[best]
                || (bursts[index] == bursts[best]
                    && (arrivals[index] < arrivals[best]
                        || (arrivals[index] == arrivals[best] && index < best))) {
                best = index;
            }
        }
        if best == process_count {
            current_time += 1;
        } else {
            order[scheduled] = best as i32;
            scheduled += 1;
            completed[best] = true;
            current_time += bursts[best];
        }
    }
    Ok(process_count)
}

#[no_mangle]
pub unsafe extern "C" fn sjfscheduling(
    input: *const i32, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut order = [0i32; MAX_PROCESSES];
    let process_count = match execute(values, &mut order) { Ok(count) => count, Err(()) => return -1 };
    let output_bytes = process_count * 4;
    if output.is_null() || output_capacity < output_bytes || output_bytes > MAX_OUTPUT_BYTES { return -2; }
    for (index, value) in order[..process_count].iter().enumerate() {
        std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(), output.add(index * 4), 4);
    }
    output_bytes as i64
}
