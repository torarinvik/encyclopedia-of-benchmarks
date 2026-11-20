const MAX_ITEMS: usize = 256;
const RUN_SIZE: usize = 8;
const MAX_RUNS: usize = 34;
type Tapes = [[i64; MAX_ITEMS]; 3];
type RunTable = [[u32; MAX_RUNS]; 3];
type TapeCounts = [u32; 3];

fn place_run(input: &[i64], length: usize, run_index: u32, tape: usize,
             tapes: &mut Tapes, starts: &mut RunTable, lengths: &mut RunTable,
             counts: &mut TapeCounts, write_offsets: &mut TapeCounts) {
    let slot = counts[tape] as usize;
    counts[tape] += 1;
    let start = write_offsets[tape] as usize;
    let source = run_index as usize * RUN_SIZE;
    let run_length = (length - source).min(RUN_SIZE);
    for i in 0..run_length { tapes[tape][start + i] = input[source + i]; }
    for i in 1..run_length {
        let value = tapes[tape][start + i];
        let mut position = i;
        while position > 0 && tapes[tape][start + position - 1] > value {
            tapes[tape][start + position] = tapes[tape][start + position - 1];
            position -= 1;
        }
        tapes[tape][start + position] = value;
    }
    starts[tape][slot] = start as u32;
    lengths[tape][slot] = run_length as u32;
    write_offsets[tape] += run_length as u32;
}

fn place_dummy(tape: usize, starts: &mut RunTable, lengths: &mut RunTable,
               counts: &mut TapeCounts, write_offsets: &TapeCounts) {
    let slot = counts[tape] as usize;
    counts[tape] += 1;
    starts[tape][slot] = write_offsets[tape];
    lengths[tape][slot] = 0;
}

fn merge_run(tapes: &mut Tapes, starts: &mut RunTable, lengths: &mut RunTable,
             counts: &mut TapeCounts, read_indices: &mut TapeCounts,
             write_offsets: &mut TapeCounts, left_tape: usize, right_tape: usize,
             output_tape: usize) {
    let left_slot = read_indices[left_tape] as usize;
    let right_slot = read_indices[right_tape] as usize;
    read_indices[left_tape] += 1;
    read_indices[right_tape] += 1;
    let left_start = starts[left_tape][left_slot] as usize;
    let right_start = starts[right_tape][right_slot] as usize;
    let left_length = lengths[left_tape][left_slot] as usize;
    let right_length = lengths[right_tape][right_slot] as usize;
    let output_slot = counts[output_tape] as usize;
    counts[output_tape] += 1;
    let output_start = write_offsets[output_tape] as usize;
    let (mut left, mut right, mut written) = (0, 0, 0);
    while left < left_length && right < right_length {
        if tapes[left_tape][left_start + left] <= tapes[right_tape][right_start + right] {
            let value = tapes[left_tape][left_start + left];
            tapes[output_tape][output_start + written] = value;
            left += 1;
        } else {
            let value = tapes[right_tape][right_start + right];
            tapes[output_tape][output_start + written] = value;
            right += 1;
        }
        written += 1;
    }
    while left < left_length {
        let value = tapes[left_tape][left_start + left];
        tapes[output_tape][output_start + written] = value;
        left += 1; written += 1;
    }
    while right < right_length {
        let value = tapes[right_tape][right_start + right];
        tapes[output_tape][output_start + written] = value;
        right += 1; written += 1;
    }
    starts[output_tape][output_slot] = output_start as u32;
    lengths[output_tape][output_slot] = written as u32;
    write_offsets[output_tape] += written as u32;
}

fn sort_values(values: &mut [i64]) {
    if values.len() < 2 || values.len() > MAX_ITEMS { return; }
    let mut tapes: Tapes = [[0; MAX_ITEMS]; 3];
    let mut starts: RunTable = [[0; MAX_RUNS]; 3];
    let mut lengths: RunTable = [[0; MAX_RUNS]; 3];
    let mut counts: TapeCounts = [0; 3];
    let mut read_indices: TapeCounts = [0; 3];
    let mut write_offsets: TapeCounts = [0; 3];
    let initial_runs = ((values.len() + RUN_SIZE - 1) / RUN_SIZE) as u32;
    let (mut quota_a, mut quota_b) = (1_u32, 0_u32);
    while quota_a + quota_b < initial_runs {
        let next = quota_a + quota_b;
        quota_b = quota_a;
        quota_a = next;
    }
    let mut run = 0_u32;
    for _ in 0..quota_a {
        if run < initial_runs {
            place_run(values, values.len(), run, 0, &mut tapes, &mut starts, &mut lengths,
                      &mut counts, &mut write_offsets);
        } else { place_dummy(0, &mut starts, &mut lengths, &mut counts, &write_offsets); }
        run += 1;
    }
    for _ in 0..quota_b {
        if run < initial_runs {
            place_run(values, values.len(), run, 1, &mut tapes, &mut starts, &mut lengths,
                      &mut counts, &mut write_offsets);
        } else { place_dummy(1, &mut starts, &mut lengths, &mut counts, &write_offsets); }
        run += 1;
    }

    let mut roles = [0_u32, 1_u32, 2_u32];
    let mut remaining_total = counts[0] + counts[1];
    while remaining_total > 1 {
        let input_a = roles[0] as usize;
        let input_b = roles[1] as usize;
        let output = roles[2] as usize;
        let available_a = counts[input_a] - read_indices[input_a];
        let available_b = counts[input_b] - read_indices[input_b];
        if available_a == 0 || available_b == 0 { break; }
        counts[output] = 0;
        read_indices[output] = 0;
        write_offsets[output] = 0;
        for _ in 0..available_a.min(available_b) {
            merge_run(&mut tapes, &mut starts, &mut lengths, &mut counts,
                      &mut read_indices, &mut write_offsets, input_a, input_b, output);
        }
        let left_a = counts[input_a] - read_indices[input_a];
        let left_b = counts[input_b] - read_indices[input_b];
        remaining_total = left_a + left_b + counts[output];
        if remaining_total <= 1 || (left_a == 0 && left_b == 0) { break; }
        if left_a > 0 {
            roles[1] = roles[2];
            roles[2] = input_b as u32;
        } else {
            roles[0] = roles[2];
            roles[2] = input_a as u32;
        }
    }
    for tape in 0..3 {
        if read_indices[tape] < counts[tape] {
            let slot = read_indices[tape] as usize;
            if lengths[tape][slot] as usize == values.len() {
                let start = starts[tape][slot] as usize;
                values.copy_from_slice(&tapes[tape][start..start + values.len()]);
                return;
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn polyphase_merge_sort(values: *mut i64, length: usize) {
    if values.is_null() || length < 2 || length > MAX_ITEMS { return; }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    sort_values(values);
}
