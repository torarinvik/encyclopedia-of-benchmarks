/// Apply updates in order and emit running even sums as little-endian i32s.
const MAX_NUMBERS: usize = 1000;
const MAX_QUERIES: usize = 1000;

#[no_mangle]
pub unsafe extern "C" fn sum_even_after_queries(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length < 5 || length > 4002 || values.is_null() { return -1; }
    let number_count_value = *values;
    let query_count_value = *values.add(1);
    if !(1..=MAX_NUMBERS as i64).contains(&number_count_value) ||
        !(1..=MAX_QUERIES as i64).contains(&query_count_value) { return -1; }
    let number_count = number_count_value as usize;
    let query_count = query_count_value as usize;
    if length != 2 + number_count + 2 * query_count { return -1; }

    let mut working = [0i64; MAX_NUMBERS];
    let mut even_sum = 0i64;
    for index in 0..number_count {
        let value = *values.add(2 + index);
        if !(1..=1000).contains(&value) { return -1; }
        working[index] = value;
        if value % 2 == 0 { even_sum += value; }
    }
    for query in 0..query_count {
        let offset = 2 + number_count + 2 * query;
        let delta = *values.add(offset);
        let index = *values.add(offset + 1);
        if !(-1000..=1000).contains(&delta) || index < 0 || index >= number_count as i64 { return -1; }
    }
    if output_capacity < query_count * 4 || output.is_null() { return -2; }

    for query in 0..query_count {
        let offset = 2 + number_count + 2 * query;
        let delta = *values.add(offset);
        let index = *values.add(offset + 1) as usize;
        if working[index] % 2 == 0 { even_sum -= working[index]; }
        working[index] += delta;
        if working[index] % 2 == 0 { even_sum += working[index]; }
        for (byte, value) in (even_sum as i32).to_le_bytes().iter().enumerate() {
            *output.add(query * 4 + byte) = *value;
        }
    }
    query_count as i64
}
