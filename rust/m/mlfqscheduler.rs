unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() { *output.add(offset + index) = *byte; }
}

#[no_mangle]
pub unsafe extern "C" fn mlfqscheduler(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 55 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let levels_value = input[0];
    let process_count_value = input[1];
    if !(1..=4).contains(&levels_value) || !(0..=16).contains(&process_count_value) { return -1; }
    let levels = levels_value as usize;
    let process_count = process_count_value as usize;
    if length != 2 + levels + 3 * process_count { return -1; }
    let mut quanta = [0i64; 4];
    let mut pids = [0i64; 16];
    let mut remaining = [0i64; 16];
    for level in 0..levels {
        quanta[level] = input[2 + level];
        if !(1..=32).contains(&quanta[level]) { return -1; }
    }
    let process_offset = 2 + levels;
    for i in 0..process_count {
        let pid = input[process_offset + 3 * i];
        let burst = input[process_offset + 3 * i + 1];
        let arrival = input[process_offset + 3 * i + 2];
        if pid < i32::MIN as i64 || pid > i32::MAX as i64 || !(0..=1000).contains(&burst) || !(0..=1_000_000).contains(&arrival) { return -1; }
        pids[i] = pid;
        remaining[i] = burst;
    }

    let mut queues = [0usize; 64];
    let mut queue_counts = [0usize; 4];
    for i in 0..process_count { queues[i] = i; }
    queue_counts[0] = process_count;
    let mut completion_pids = [0i64; 16];
    let mut completion_times = [0i64; 16];
    let mut completions = 0usize;
    let mut current_time = 0i64;
    loop {
        let mut active = 0usize;
        for level in 0..levels { active += queue_counts[level]; }
        if active == 0 { break; }
        for level in 0..levels {
            let base = level * 16;
            let queued = queue_counts[level];
            if queued == 0 { continue; }
            let process = queues[base];
            for j in 1..queued { queues[base + j - 1] = queues[base + j]; }
            queue_counts[level] -= 1;
            let slice = quanta[level].min(remaining[process]);
            current_time += slice;
            remaining[process] -= slice;
            if remaining[process] == 0 {
                completion_pids[completions] = pids[process];
                completion_times[completions] = current_time;
                completions += 1;
            } else {
                let destination = if level + 1 < levels { level + 1 } else { level };
                queues[destination * 16 + queue_counts[destination]] = process;
                queue_counts[destination] += 1;
            }
        }
    }

    let elements = 2 + 2 * completions;
    let required = elements * 8;
    if output.is_null() || output_capacity < required { return -2; }
    put_i64_le(output, 0, current_time);
    put_i64_le(output, 8, completions as i64);
    for i in 0..completions {
        put_i64_le(output, 16 + 16 * i, completion_pids[i]);
        put_i64_le(output, 24 + 16 * i, completion_times[i]);
    }
    elements as i64
}
