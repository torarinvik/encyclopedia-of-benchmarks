const MAX_N: usize = 32;
const MAX_Q: usize = 16;
const MAX_BLOCKS: usize = 6;
const MAX_INPUT_LENGTH: usize = 66;

fn lower_bound_i64(values: &[i64], target: i64) -> usize {
    let (mut begin, mut end) = (0, values.len());
    while begin < end {
        let middle = begin + (end - begin) / 2;
        if values[middle] < target { begin = middle + 1; } else { end = middle; }
    }
    begin
}

fn lower_bound_usize(values: &[usize], mut begin: usize, mut end: usize, target: usize) -> usize {
    while begin < end {
        let middle = begin + (end - begin) / 2;
        if values[middle] < target { begin = middle + 1; } else { end = middle; }
    }
    begin
}

fn range_frequency(occurrences: &[usize], offsets: &[usize], id: usize,
                   left: usize, right: usize) -> usize {
    let begin = offsets[id];
    let end = offsets[id + 1];
    lower_bound_usize(occurrences, begin, end, right) -
        lower_bound_usize(occurrences, begin, end, left)
}

fn write_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn static_range_mode_query(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let q_value = values[1];
    if n_value < 1 || n_value > MAX_N as i64 || q_value < 1 || q_value > MAX_Q as i64 { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 2 + n + 2 * q { return -1; }
    for index in 0..n {
        if values[2 + index] < 0 || values[2 + index] > 1_000_000_000 { return -1; }
    }
    for query in 0..q {
        let left = values[2 + n + 2 * query];
        let right = values[3 + n + 2 * query];
        if left < 0 || right <= left || right > n_value { return -1; }
    }
    if output.is_null() || output_capacity < 16 * q { return -2; }

    let mut sorted = [0_i64; MAX_N];
    let mut unique_values = [0_i64; MAX_N];
    let mut compressed = [0_usize; MAX_N];
    let mut frequencies = [0_usize; MAX_N];
    let mut offsets = [0_usize; MAX_N + 1];
    let mut cursor = [0_usize; MAX_N];
    let mut occurrences = [0_usize; MAX_N];
    let mut block_mode = [0_usize; MAX_BLOCKS * MAX_BLOCKS];
    for index in 0..n {
        let value = values[2 + index];
        let mut position = index;
        while position > 0 && sorted[position - 1] > value {
            sorted[position] = sorted[position - 1];
            position -= 1;
        }
        sorted[position] = value;
    }
    let mut distinct = 0;
    for index in 0..n {
        if distinct == 0 || sorted[index] != unique_values[distinct - 1] {
            unique_values[distinct] = sorted[index];
            distinct += 1;
        }
    }
    for index in 0..n {
        let id = lower_bound_i64(&unique_values[..distinct], values[2 + index]);
        compressed[index] = id;
        frequencies[id] += 1;
    }
    for id in 0..distinct { offsets[id + 1] = offsets[id] + frequencies[id]; }
    cursor[..distinct].copy_from_slice(&offsets[..distinct]);
    for index in 0..n {
        let id = compressed[index];
        occurrences[cursor[id]] = index;
        cursor[id] += 1;
    }

    let mut block_size = 1;
    while block_size * block_size < n { block_size += 1; }
    let block_count = (n + block_size - 1) / block_size;
    let mut frequency = [0_usize; MAX_N];
    for first in 0..block_count {
        frequency.fill(0);
        let (mut best_id, mut best_count) = (0, 0);
        for last in first..block_count {
            let begin = last * block_size;
            let end = n.min(begin + block_size);
            for index in begin..end {
                let id = compressed[index];
                frequency[id] += 1;
                let count = frequency[id];
                if count > best_count || (count == best_count && id < best_id) {
                    best_id = id;
                    best_count = count;
                }
            }
            block_mode[first * MAX_BLOCKS + last] = best_id;
        }
    }

    for query in 0..q {
        let left = values[2 + n + 2 * query] as usize;
        let right = values[3 + n + 2 * query] as usize;
        let first_full = (left + block_size - 1) / block_size;
        let after_full = right / block_size;
        let (mut best_id, mut best_count) = (0, 0);
        if first_full < after_full {
            best_id = block_mode[first_full * MAX_BLOCKS + after_full - 1];
            best_count = range_frequency(&occurrences, &offsets, best_id, left, right);
            let span_start = first_full * block_size;
            let span_end = after_full * block_size;
            for index in left..span_start {
                let id = compressed[index];
                let count = range_frequency(&occurrences, &offsets, id, left, right);
                if count > best_count || (count == best_count && id < best_id) {
                    best_id = id;
                    best_count = count;
                }
            }
            for index in span_end..right {
                let id = compressed[index];
                let count = range_frequency(&occurrences, &offsets, id, left, right);
                if count > best_count || (count == best_count && id < best_id) {
                    best_id = id;
                    best_count = count;
                }
            }
        } else {
            for index in left..right {
                let id = compressed[index];
                let count = range_frequency(&occurrences, &offsets, id, left, right);
                if count > best_count || (count == best_count && id < best_id) {
                    best_id = id;
                    best_count = count;
                }
            }
        }
        write_i64(output, 16 * query, unique_values[best_id]);
        write_i64(output, 16 * query + 8, best_count as i64);
    }
    (16 * q) as i64
}
