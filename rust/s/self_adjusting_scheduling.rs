const MAX_TASKS: usize = 16;
const MAX_STEPS: usize = 64;
const MAX_INPUT_LENGTH: usize = MAX_TASKS + 3;

#[no_mangle]
pub unsafe extern "C" fn self_adjusting_scheduling(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let task_count_value = values[0];
    let steps_value = values[1];
    if !(1..=MAX_TASKS as i64).contains(&task_count_value)
        || !(0..=MAX_STEPS as i64).contains(&steps_value)
        || length != task_count_value as usize + 2
    {
        return -1;
    }

    let task_count = task_count_value as usize;
    let steps = steps_value as usize;
    let mut priorities = [0i64; MAX_TASKS];
    let mut wait_times = [0i64; MAX_TASKS];
    let mut schedule = [0u8; MAX_STEPS];
    for task in 0..task_count {
        let priority = values[task + 2];
        if priority < i32::MIN as i64 || priority > i32::MAX as i64 {
            return -1;
        }
        priorities[task] = priority;
    }

    for step in 0..steps {
        for left in 0..task_count {
            for right in left + 1..task_count {
                if priorities[left] == priorities[right] {
                    return -1;
                }
            }
        }
        let mut selected = 0usize;
        for task in 1..task_count {
            if priorities[task] < priorities[selected] {
                selected = task;
            }
        }
        schedule[step] = selected as u8;
        wait_times[selected] += 1;
        let updated_priority = priorities[selected] + wait_times[selected];
        if updated_priority < i32::MIN as i64 || updated_priority > i32::MAX as i64 {
            return -1;
        }
        priorities[selected] = updated_priority;
    }

    if output.is_null() || capacity < steps {
        return -2;
    }
    std::ptr::copy_nonoverlapping(schedule.as_ptr(), output, steps);
    steps as i64
}
