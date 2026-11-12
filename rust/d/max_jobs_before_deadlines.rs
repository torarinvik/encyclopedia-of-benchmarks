use std::cmp::Reverse;
use std::collections::BinaryHeap;

const MAX_JOBS: usize = 12;

#[derive(Clone, Copy)]
struct Job {
    deadline: i64,
    duration: i64,
    id: usize,
}

#[no_mangle]
pub unsafe extern "C" fn max_jobs_before_deadlines(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=1 + 2 * MAX_JOBS).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    if !(0..=MAX_JOBS as i64).contains(&count_value)
        || length != 1 + 2 * count_value as usize
    {
        return -1;
    }
    let count = count_value as usize;
    let mut jobs = Vec::with_capacity(count);
    for id in 0..count {
        let deadline = values[1 + 2 * id];
        let duration = values[2 + 2 * id];
        if !(0..=1000).contains(&deadline) || !(1..=1000).contains(&duration) {
            return -1;
        }
        jobs.push(Job { deadline, duration, id });
    }
    jobs.sort_by_key(|job| (job.deadline, job.id));

    let mut available = BinaryHeap::<Reverse<(i64, usize)>>::with_capacity(count);
    let mut completed = 0_i64;
    for index in (0..count).rev() {
        let job = jobs[index];
        available.push(Reverse((job.duration, job.id)));
        let lower_deadline = if index == 0 { 0 } else { jobs[index - 1].deadline };
        let mut interval = job.deadline - lower_deadline;
        while interval > 0 {
            let Some(Reverse((remaining, id))) = available.pop() else { break };
            if remaining <= interval {
                interval -= remaining;
                completed += 1;
            } else {
                available.push(Reverse((remaining - interval, id)));
                interval = 0;
            }
        }
    }
    completed
}
