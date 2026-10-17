const MAX_QUEUES: usize = 4;
const MAX_PROCESSES: usize = 8;
const MAX_INPUT_WORDS: usize = 13;
const MAX_OUTPUT_WORDS: usize = 1 + 4 * MAX_PROCESSES;

#[derive(Clone, Copy, Default)]
struct Process { id: i32, remaining: i32, waiting: i32, turnaround: i32, stop_time: i32 }

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn multi_level_feedback_queue(
    input: *const i32, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_WORDS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let queue_count = values[0];
    let process_count = values[1];
    if !(1..=MAX_QUEUES as i32).contains(&queue_count) ||
        !(0..=MAX_PROCESSES as i32).contains(&process_count) ||
        length != 2 + (queue_count - 1) as usize + process_count as usize { return -1; }

    let mut slices = [0i32; MAX_QUEUES - 1];
    let mut pos = 2usize;
    for i in 0..(queue_count - 1) as usize {
        if !(1..=16).contains(&values[pos]) { return -1; }
        slices[i] = values[pos];
        pos += 1;
    }
    let mut ready = [Process::default(); MAX_PROCESSES];
    let mut ready_count = process_count as usize;
    for i in 0..process_count as usize {
        let burst = values[pos];
        pos += 1;
        if !(1..=16).contains(&burst) { return -1; }
        ready[i] = Process { id: i as i32, remaining: burst, waiting: 0, turnaround: 0, stop_time: 0 };
    }

    let mut finished = [Process::default(); MAX_PROCESSES];
    let mut finished_count = 0usize;
    let mut current_time = 0i32;
    for level in 0..(queue_count - 1) as usize {
        let mut next_ready = [Process::default(); MAX_PROCESSES];
        let mut next_count = 0usize;
        let time_slice = slices[level];
        for i in 0..ready_count {
            let mut process = ready[i];
            process.waiting += current_time - process.stop_time;
            if process.remaining > time_slice {
                current_time += time_slice;
                process.remaining -= time_slice;
                process.stop_time = current_time;
                next_ready[next_count] = process;
                next_count += 1;
            } else {
                current_time += process.remaining;
                process.remaining = 0;
                process.stop_time = current_time;
                process.turnaround = current_time;
                finished[finished_count] = process;
                finished_count += 1;
            }
        }
        ready_count = next_count;
        ready[..next_count].copy_from_slice(&next_ready[..next_count]);
    }
    for i in 0..ready_count {
        let mut process = ready[i];
        process.waiting += current_time - process.stop_time;
        current_time += process.remaining;
        process.remaining = 0;
        process.stop_time = current_time;
        process.turnaround = current_time;
        finished[finished_count] = process;
        finished_count += 1;
    }

    if finished_count != process_count as usize { return -1; }
    let mut words = [0i32; MAX_OUTPUT_WORDS];
    let mut word_count = 1usize;
    words[0] = process_count;
    for process in finished.iter().take(finished_count) {
        words[word_count] = process.id;
        words[word_count + 1] = process.waiting;
        words[word_count + 2] = process.turnaround;
        words[word_count + 3] = process.stop_time;
        word_count += 4;
    }
    let bytes = word_count * 4;
    if output.is_null() || capacity < bytes { return -2; }
    let mut buffer = [0u8; MAX_OUTPUT_WORDS * 4];
    for i in 0..word_count { put_i32_le(&mut buffer, i * 4, words[i]); }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}
