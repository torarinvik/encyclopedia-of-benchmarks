const MAX_BLOCK_COUNT: usize = 16;
const MAX_PROCESS_COUNT: usize = 32;
const MAX_INPUT_LENGTH: usize = 52;
const MAX_OUTPUT_BYTES: usize = 256;
const NO_ALLOCATION: i64 = -255;

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn memory_management_algorithms(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let policy = values[0];
    if !(0..=3).contains(&policy) || !(1..=MAX_BLOCK_COUNT as i64).contains(&values[1]) ||
        !(0..=MAX_PROCESS_COUNT as i64).contains(&values[2]) { return -1; }
    let block_count = values[1] as usize;
    let process_count = values[2] as usize;
    if input_length != 3 + block_count + process_count { return -1; }

    let mut blocks = [0_i64; MAX_BLOCK_COUNT];
    let mut processes = [0_i64; MAX_PROCESS_COUNT];
    for index in 0..block_count {
        let size = values[3 + index];
        if !(1..=10_000).contains(&size) { return -1; }
        blocks[index] = size;
    }
    for index in 0..process_count {
        let size = values[3 + block_count + index];
        if !(1..=10_000).contains(&size) { return -1; }
        processes[index] = size;
    }

    let mut allocations = [0_i64; MAX_PROCESS_COUNT];
    let mut next_fit_counter = 0_i64;
    for process_index in 0..process_count {
        let process = processes[process_index];
        let mut selected = NO_ALLOCATION;
        if policy == 0 {
            for index in 0..block_count {
                if blocks[index] >= process { selected = index as i64; break; }
            }
        } else if policy == 1 {
            let mut min_diff = blocks[..block_count].iter().copied().max().unwrap_or(0);
            for index in 0..block_count {
                let difference = blocks[index] - process;
                if difference < min_diff && difference >= 0 {
                    min_diff = difference;
                    selected = index as i64;
                }
            }
        } else if policy == 2 {
            let mut best = 0_usize;
            for candidate in 1..block_count {
                if blocks[candidate] > blocks[best] { best = candidate; }
            }
            if blocks[best] >= process { selected = best as i64; }
        } else {
            let mut found = false;
            for offset in 0..block_count {
                if next_fit_counter + offset as i64 >= block_count as i64 {
                    next_fit_counter = -(offset as i64);
                }
                let index = (offset as i64 + next_fit_counter) as usize;
                if blocks[index] >= process {
                    next_fit_counter += offset as i64;
                    selected = next_fit_counter;
                    found = true;
                    break;
                }
            }
            if !found { next_fit_counter += block_count as i64; }
        }
        allocations[process_index] = selected;
        if selected != NO_ALLOCATION { blocks[selected as usize] -= process; }
    }

    let output_bytes = process_count * 8;
    if output_bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || capacity < output_bytes { return -2; }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..process_count { write_i64_le(output_slice, index * 8, allocations[index]); }
    output_bytes as i64
}
