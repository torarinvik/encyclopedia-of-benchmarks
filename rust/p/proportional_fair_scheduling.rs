unsafe fn store_i64_le(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(position + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn proportional_fair_scheduling(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || !(2..=131).contains(&length) { return -1; }
    let process_count_value = *values;
    let total_resources = *values.add(1);
    if !(0..=64).contains(&process_count_value) || !(1..=1_000_000).contains(&total_resources) { return -1; }
    let process_count = process_count_value as usize;
    if length != 2 + 2 * process_count { return -1; }

    let mut name_ids = [0_i64; 64];
    let mut weights = [0_i64; 64];
    let mut total_weight = 0_i64;
    for process in 0..process_count {
        let name_id = *values.add(2 + 2 * process);
        let weight = *values.add(3 + 2 * process);
        if !(i32::MIN as i64..=i32::MAX as i64).contains(&name_id)
            || !(1..=1_000_000).contains(&weight) { return -1; }
        name_ids[process] = name_id;
        weights[process] = weight;
        total_weight += weight;
    }

    if process_count == 0 { return 0; }
    let required = process_count * 16;
    if output.is_null() || output_capacity < required { return -2; }
    for process in 0..process_count {
        let quotient = weights[process] as f64 / total_weight as f64;
        let share = quotient * total_resources as f64;
        let allocation = share as i32;
        store_i64_le(output, process * 16, name_ids[process]);
        store_i64_le(output, process * 16 + 8, allocation as i64);
    }
    required as i64
}
