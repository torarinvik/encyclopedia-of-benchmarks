/// Enumerate positive value lists in include-first source order.
fn write_i64_le(output: *mut u8, position: &mut usize, value: i64) {
    for byte in value.to_le_bytes() {
        unsafe { output.add(*position).write(byte); }
        *position += 1;
    }
}

fn enumerate(items: &[i64], index: usize, target: i64, total: i64,
             chosen: &mut [i64; 11], chosen_count: usize,
             output: *mut u8, position: &mut usize, emit: bool) -> usize {
    if total == target {
        if emit {
            write_i64_le(output, position, chosen_count as i64);
            for &value in &chosen[..chosen_count] { write_i64_le(output, position, value); }
        }
        return chosen_count + 1;
    }
    if index == items.len() || total > target { return 0; }
    chosen[chosen_count] = items[index];
    let include_slots = enumerate(items, index + 1, target, total + items[index],
        chosen, chosen_count + 1, output, position, emit);
    let exclude_slots = enumerate(items, index + 1, target, total,
        chosen, chosen_count, output, position, emit);
    include_slots + exclude_slots
}

#[no_mangle]
pub extern "C" fn subset_sum_values_enumeration(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > 12 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let target = values[0];
    if !(0..=256).contains(&target) || values[1..].iter().any(|&item| !(1..=64).contains(&item)) {
        return -1;
    }
    let mut chosen = [0i64; 11];
    let mut dummy_position = 0usize;
    let slots = enumerate(&values[1..], 0, target, 0, &mut chosen, 0,
        std::ptr::null_mut(), &mut dummy_position, false);
    let required = slots * 8;
    if required == 0 { return 0; }
    if output.is_null() || output_capacity < required { return -2; }
    let mut position = 0usize;
    enumerate(&values[1..], 0, target, 0, &mut chosen, 0, output, &mut position, true);
    position as i64
}
