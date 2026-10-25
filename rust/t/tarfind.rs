// Bounded clean-room TAR-header filename search benchmark.
// Embench-IoT source declares MIT; see the package attribution.
// SPDX-License-Identifier: MIT
const MAX_RECORDS: usize = 35;
const MAX_QUERIES: usize = 5;
const MIN_NAME_LENGTH: usize = 5;
const MAX_NAME_LENGTH: usize = 39;
const MAX_INPUT_LENGTH: usize =
    2 + MAX_RECORDS * (1 + MAX_NAME_LENGTH) + MAX_QUERIES * (1 + MAX_NAME_LENGTH);

#[no_mangle]
pub unsafe extern "C" fn tarfind(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, input_length);
    if values[0] < 1 || values[0] > MAX_RECORDS as i64 ||
        values[1] < 1 || values[1] > MAX_QUERIES as i64 { return -1; }
    let record_count = values[0] as usize;
    let query_count = values[1] as usize;
    let mut record_offsets = [0usize; MAX_RECORDS];
    let mut record_lengths = [0usize; MAX_RECORDS];
    let mut query_offsets = [0usize; MAX_QUERIES];
    let mut query_lengths = [0usize; MAX_QUERIES];
    let mut staged = [0u8; MAX_QUERIES];
    let mut position = 2usize;

    for i in 0..record_count {
        if position >= input_length { return -1; }
        let raw_length = values[position];
        position += 1;
        if raw_length < MIN_NAME_LENGTH as i64 || raw_length > MAX_NAME_LENGTH as i64 { return -1; }
        let name_length = raw_length as usize;
        if name_length > input_length - position { return -1; }
        record_offsets[i] = position;
        record_lengths[i] = name_length;
        for j in 0..name_length {
            if values[position + j] < 65 || values[position + j] > 90 { return -1; }
        }
        position += name_length;
    }
    for i in 0..query_count {
        if position >= input_length { return -1; }
        let raw_length = values[position];
        position += 1;
        if raw_length < MIN_NAME_LENGTH as i64 || raw_length > MAX_NAME_LENGTH as i64 { return -1; }
        let name_length = raw_length as usize;
        if name_length > input_length - position { return -1; }
        query_offsets[i] = position;
        query_lengths[i] = name_length;
        for j in 0..name_length {
            if values[position + j] < 65 || values[position + j] > 90 { return -1; }
        }
        position += name_length;
    }
    if position != input_length { return -1; }
    if output.is_null() || output_capacity < query_count { return -2; }

    for q in 0..query_count {
        let mut found: i64 = -1;
        for i in 0..record_count {
            if record_lengths[i] != query_lengths[q] { continue; }
            let mut j = 0usize;
            while j < query_lengths[q] && values[record_offsets[i] + j] == values[query_offsets[q] + j] {
                j += 1;
            }
            if j == query_lengths[q] {
                found = i as i64;
                break;
            }
        }
        staged[q] = if found < 0 { u8::MAX } else { found as u8 };
    }
    for q in 0..query_count {
        output.add(q).write(staged[q]);
    }
    query_count as i64
}
