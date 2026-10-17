const MAX_JOBS: usize = 64;
const MAX_OUTPUT: usize = 4 + 12 * MAX_JOBS;

#[derive(Clone, Copy)]
struct Job {
    processing: i32,
    deadline: i32,
    original_index: i32,
    start_time: i32,
    lateness: i32,
}

fn write_i32(output: &mut [u8; MAX_OUTPUT], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn minimizing_lateness(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=1 + 2 * MAX_JOBS).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(0..=MAX_JOBS as i64).contains(&count_value) || length != 1 + 2 * count_value as usize { return -1; }
    let count = count_value as usize;
    let mut jobs = [Job { processing: 0, deadline: 0, original_index: 0, start_time: 0, lateness: 0 }; MAX_JOBS];
    let mut total_processing = 0_i64;
    for i in 0..count {
        let processing = values[1 + 2 * i];
        let deadline = values[2 + 2 * i];
        if !(0..=i32::MAX as i64).contains(&processing) || !(0..=i32::MAX as i64).contains(&deadline) { return -1; }
        total_processing += processing;
        if total_processing > i32::MAX as i64 { return -1; }
        jobs[i] = Job { processing: processing as i32, deadline: deadline as i32,
            original_index: i as i32, start_time: 0, lateness: 0 };
    }
    for i in 1..count {
        let item = jobs[i];
        let mut position = i;
        while position > 0 && jobs[position - 1].deadline > item.deadline {
            jobs[position] = jobs[position - 1];
            position -= 1;
        }
        jobs[position] = item;
    }
    let mut start_time = 0_i64;
    for job in jobs.iter_mut().take(count) {
        job.start_time = start_time as i32;
        let finish_time = start_time + job.processing as i64;
        job.lateness = (finish_time - job.deadline as i64).max(0) as i32;
        start_time = finish_time;
    }
    let needed = 4 + 12 * count;
    if output.is_null() || capacity < needed { return -2; }
    let mut payload = [0_u8; MAX_OUTPUT];
    write_i32(&mut payload, 0, count as i32);
    for i in 0..count {
        let offset = 4 + 12 * i;
        write_i32(&mut payload, offset, jobs[i].original_index);
        write_i32(&mut payload, offset + 4, jobs[i].start_time);
        write_i32(&mut payload, offset + 8, jobs[i].lateness);
    }
    std::ptr::copy_nonoverlapping(payload.as_ptr(), output, needed);
    needed as i64
}
