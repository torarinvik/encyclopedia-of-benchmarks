const MIN_TARGET: i64 = -4096;
const MAX_TARGET: i64 = 4096;
const MAX_DENOMINATIONS: usize = 32;
const MAX_INPUT_VALUES: usize = 2 + MAX_DENOMINATIONS;
const MAX_OUTPUT_BYTES: usize = (1 + MAX_TARGET as usize) * 4;

fn write_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn minimum_coin_change_greedy(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_VALUES).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let target = values[0];
    let count_value = values[1];
    if !(MIN_TARGET..=MAX_TARGET).contains(&target) ||
        !(0..=MAX_DENOMINATIONS as i64).contains(&count_value) { return -1; }
    let denomination_count = count_value as usize;
    if length != 2 + denomination_count { return -1; }

    let mut denominations = [0i32; MAX_DENOMINATIONS];
    let mut previous = 0i64;
    for index in 0..denomination_count {
        let denomination = values[2 + index];
        if !(1..=4096).contains(&denomination) || denomination <= previous { return -1; }
        denominations[index] = denomination as i32;
        previous = denomination;
    }

    let mut chosen = [0i32; 4096];
    let mut chosen_count = 0usize;
    if target > 0 {
        let mut remaining = target;
        for index in (0..denomination_count).rev() {
            let denomination = denominations[index];
            while remaining >= denomination as i64 {
                remaining -= denomination as i64;
                chosen[chosen_count] = denomination;
                chosen_count += 1;
            }
        }
    }

    let needed = (1 + chosen_count) * 4;
    if output.is_null() || capacity < needed { return -2; }
    write_i32_le(output, 0, chosen_count as i32);
    for index in 0..chosen_count {
        write_i32_le(output, 4 + 4 * index, chosen[index]);
    }
    needed as i64
}
