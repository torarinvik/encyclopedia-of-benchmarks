const MAX_PROCESSES: usize = 8;
const MAX_SCHEDULE_TICKS: usize = 80;
const MAX_OUTPUT_WORDS: usize = 81;

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn preemptive_priority_scheduling(
    input: *const i32, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > 33 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let process_count = values[0];
    if !(0..=MAX_PROCESSES as i32).contains(&process_count) ||
        length != 1 + 4 * process_count as usize { return -1; }

    let mut ids = [0i32; MAX_PROCESSES];
    let mut arrivals = [0i32; MAX_PROCESSES];
    let mut remaining = [0i32; MAX_PROCESSES];
    let mut priorities = [0i32; MAX_PROCESSES];
    let mut seen_ids = [false; MAX_PROCESSES];
    for i in 0..process_count as usize {
        let offset = 1 + 4 * i;
        let id = values[offset];
        let arrival = values[offset + 1];
        let burst = values[offset + 2];
        let priority = values[offset + 3];
        if !(0..MAX_PROCESSES as i32).contains(&id) || seen_ids[id as usize] ||
            !(0..=16).contains(&arrival) || !(1..=8).contains(&burst) { return -1; }
        for previous in 0..i {
            if priorities[previous] == priority && arrivals[previous] == arrival { return -1; }
        }
        seen_ids[id as usize] = true;
        ids[i] = id;
        arrivals[i] = arrival;
        remaining[i] = burst;
        priorities[i] = priority;
    }

    let mut schedule = [0i32; MAX_SCHEDULE_TICKS];
    let mut tick_count = 0usize;
    let mut completed = 0usize;
    while completed < process_count as usize {
        let mut best = process_count as usize;
        for i in 0..process_count as usize {
            if remaining[i] <= 0 || arrivals[i] > tick_count as i32 { continue; }
            if best == process_count as usize || priorities[i] > priorities[best] ||
                (priorities[i] == priorities[best] && arrivals[i] < arrivals[best]) { best = i; }
        }
        if best == process_count as usize {
            schedule[tick_count] = -1;
        } else {
            schedule[tick_count] = ids[best];
            remaining[best] -= 1;
            if remaining[best] == 0 { completed += 1; }
        }
        tick_count += 1;
    }

    let bytes = (1 + tick_count) * 4;
    if output.is_null() || capacity < bytes { return -2; }
    let mut buffer = [0u8; MAX_OUTPUT_WORDS * 4];
    put_i32_le(&mut buffer, 0, tick_count as i32);
    for i in 0..tick_count { put_i32_le(&mut buffer, 4 * (i + 1), schedule[i]); }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}
