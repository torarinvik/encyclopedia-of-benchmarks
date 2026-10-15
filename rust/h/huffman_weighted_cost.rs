const MAX_SYMBOLS: usize = 26;
const MAX_TOTAL_FREQUENCY: i64 = 2_147_483_647;

fn store_i64_le(output: &mut [u8], value: i64) {
    output[..8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn huffman_weighted_cost(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 1 || length > 53 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let raw_count = input[0];
    if !(2..=MAX_SYMBOLS as i64).contains(&raw_count) || length != 1 + 2 * raw_count as usize { return -1; }
    let count = raw_count as usize;

    let mut seen = [false; MAX_SYMBOLS];
    let mut active = [false; MAX_SYMBOLS];
    let mut weights = [0i64; MAX_SYMBOLS];
    let mut total = 0i64;
    for index in 0..count {
        let symbol = input[1 + 2 * index];
        let frequency = input[2 + 2 * index];
        if !(97..=122).contains(&symbol) || !(1..=MAX_TOTAL_FREQUENCY).contains(&frequency) { return -1; }
        let letter = (symbol - 97) as usize;
        if seen[letter] || total > MAX_TOTAL_FREQUENCY - frequency { return -1; }
        seen[letter] = true;
        active[index] = true;
        weights[index] = frequency;
        total += frequency;
    }

    let mut remaining = count;
    let mut cost = 0i64;
    while remaining > 1 {
        let mut first = usize::MAX;
        let mut second = usize::MAX;
        for index in 0..count {
            if !active[index] { continue; }
            if first == usize::MAX || weights[index] < weights[first] {
                second = first;
                first = index;
            } else if second == usize::MAX || weights[index] < weights[second] {
                second = index;
            }
        }
        weights[first] += weights[second];
        active[second] = false;
        cost += weights[first];
        remaining -= 1;
    }

    if output.is_null() || capacity < 8 { return -2; }
    let result = unsafe { std::slice::from_raw_parts_mut(output, 8) };
    store_i64_le(result, cost);
    cost
}
