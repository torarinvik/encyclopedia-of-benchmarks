fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn sort_population(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=129).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=64).contains(&values[0]) {
        return -1;
    }
    let count = values[0] as usize;
    if length != 1 + 2 * count {
        return -1;
    }
    let mut costs = [0i64; 64];
    let mut identifiers = [0i64; 64];
    let mut seen = [false; 64];
    for index in 0..count {
        let cost = values[1 + 2 * index];
        let identifier = values[2 + 2 * index];
        if !(-1_000_000..=1_000_000).contains(&cost)
            || identifier < 0
            || identifier >= count as i64
        {
            return -1;
        }
        if seen[identifier as usize] {
            return -1;
        }
        seen[identifier as usize] = true;
        costs[index] = cost;
        identifiers[index] = identifier;
    }
    for index in 1..count {
        let key_cost = costs[index];
        let key_identifier = identifiers[index];
        let mut position = index;
        while position > 0 && costs[position - 1] > key_cost {
            costs[position] = costs[position - 1];
            identifiers[position] = identifiers[position - 1];
            position -= 1;
        }
        costs[position] = key_cost;
        identifiers[position] = key_identifier;
    }
    for index in 1..count {
        if costs[index - 1] == costs[index] {
            return -1;
        }
    }
    let output_length = count * 16;
    if output.is_null() || capacity < output_length {
        return -2;
    }
    let bytes = std::slice::from_raw_parts_mut(output, output_length);
    for index in 0..count {
        write_i64_le(bytes, index * 16, costs[index]);
        write_i64_le(bytes, index * 16 + 8, identifiers[index]);
    }
    output_length as i64
}
