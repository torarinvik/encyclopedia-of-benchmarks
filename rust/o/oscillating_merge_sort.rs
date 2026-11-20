/* Bounded multi-tape merge with alternating run directions and backward reads. */
const MAX_VALUES: usize = 1024;
const MAX_PARTS: usize = 2;
const INITIAL_RUN_SIZE: usize = 16;

fn build_run(values: &[i64], run_size: usize, merge_inputs: usize,
             first_run: usize, run_count: usize, ascending: bool,
             output: &mut [i64]) -> usize {
    if run_count == 1 {
        let start = first_run * run_size;
        let length = (values.len() - start).min(run_size);
        output[..length].copy_from_slice(&values[start..start + length]);
        for index in 1..length {
            let value = output[index];
            let mut position = index;
            while position > 0 && (if ascending { value < output[position - 1] }
                                    else { value > output[position - 1] }) {
                output[position] = output[position - 1];
                position -= 1;
            }
            output[position] = value;
        }
        return length;
    }

    let mut children = [[0_i64; MAX_VALUES]; MAX_PARTS];
    let mut lengths = [0_usize; MAX_PARTS];
    let mut positions = [0_usize; MAX_PARTS];
    let quotient = run_count / merge_inputs;
    let remainder = run_count % merge_inputs;
    let mut next_run = first_run;
    let mut total = 0;
    for lane in 0..merge_inputs {
        let child_count = quotient + (lane < remainder) as usize;
        if child_count == 0 { continue; }
        lengths[lane] = build_run(values, run_size, merge_inputs, next_run,
                                  child_count, !ascending, &mut children[lane]);
        next_run += child_count;
        total += lengths[lane];
    }
    for out in 0..total {
        let mut best_lane = MAX_PARTS;
        let mut best_value = 0_i64;
        for lane in 0..merge_inputs {
            if positions[lane] >= lengths[lane] { continue; }
            let candidate = children[lane][lengths[lane] - 1 - positions[lane]];
            if best_lane == MAX_PARTS
                || (if ascending { candidate < best_value } else { candidate > best_value }) {
                best_lane = lane;
                best_value = candidate;
            }
        }
        output[out] = best_value;
        positions[best_lane] += 1;
    }
    total
}

#[no_mangle]
pub unsafe extern "C" fn oscillating_merge_sort(values: *mut i64, length: usize) {
    if length == 0 || length > MAX_VALUES || values.is_null() { return; }
    let input = std::slice::from_raw_parts(values, length);
    let mut sorted = [0_i64; MAX_VALUES];
    let run_count = (length + INITIAL_RUN_SIZE - 1) / INITIAL_RUN_SIZE;
    build_run(input, INITIAL_RUN_SIZE, MAX_PARTS, 0, run_count, true, &mut sorted);
    std::slice::from_raw_parts_mut(values, length).copy_from_slice(&sorted[..length]);
}
