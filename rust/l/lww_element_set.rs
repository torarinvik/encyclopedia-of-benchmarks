const MAX_OPERATIONS: usize = 24;
const MAX_KEYS: usize = 24;
const MAP_COUNT: usize = 4;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1 + 4 * MAX_OPERATIONS + 1;
const I32_MIN: i64 = -2_147_483_648;
const I32_MAX: i64 = 2_147_483_647;

#[no_mangle]
pub unsafe extern "C" fn lww_element_set(input: *const i64, input_length: usize) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let operation_count_value = values[0];
    if !(0..=MAX_OPERATIONS as i64).contains(&operation_count_value) { return -1; }
    let operation_count = operation_count_value as usize;
    if input_length != 1 + 4 * operation_count { return -1; }

    let mut keys = [0i64; MAP_COUNT * MAX_KEYS];
    let mut timestamps = [0i64; MAP_COUNT * MAX_KEYS];
    let mut map_counts = [0usize; MAP_COUNT];
    let mut lookup_mask = 0i64;
    let mut lookup_index = 0usize;

    for operation in 0..operation_count {
        let offset = 1 + 4 * operation;
        let opcode = values[offset];
        let first = values[offset + 1];
        let second = values[offset + 2];
        let third = values[offset + 3];
        if opcode == 0 || opcode == 1 {
            if !(0..=1).contains(&first) || !(I32_MIN..=I32_MAX).contains(&second) ||
                !(I32_MIN..=I32_MAX).contains(&third) { return -1; }
            let map_index = first as usize * 2 + if opcode == 1 { 1 } else { 0 };
            let base = map_index * MAX_KEYS;
            let mut position = 0;
            while position < map_counts[map_index] && keys[base + position] != second { position += 1; }
            if position == map_counts[map_index] {
                if map_counts[map_index] >= MAX_KEYS { return -1; }
                keys[base + position] = second;
                map_counts[map_index] += 1;
            }
            timestamps[base + position] = third;
        } else if opcode == 2 {
            if !(0..=1).contains(&first) || !(I32_MIN..=I32_MAX).contains(&second) || third != 0 { return -1; }
            let add_map = first as usize * 2;
            let add_base = add_map * MAX_KEYS;
            let remove_map = add_map + 1;
            let remove_base = remove_map * MAX_KEYS;
            let mut add_position = 0;
            let mut remove_position = 0;
            while add_position < map_counts[add_map] && keys[add_base + add_position] != second { add_position += 1; }
            while remove_position < map_counts[remove_map] && keys[remove_base + remove_position] != second { remove_position += 1; }
            if add_position < map_counts[add_map] &&
                (remove_position == map_counts[remove_map] ||
                 timestamps[add_base + add_position] > timestamps[remove_base + remove_position]) {
                lookup_mask |= 1i64 << lookup_index;
            }
            lookup_index += 1;
        } else if opcode == 3 {
            if !(0..=1).contains(&first) || !(0..=1).contains(&second) || third != 0 { return -1; }
            if first != second {
                for kind in 0..2 {
                    let target_map = first as usize * 2 + kind;
                    let source_map = second as usize * 2 + kind;
                    let target_base = target_map * MAX_KEYS;
                    let source_base = source_map * MAX_KEYS;
                    for source_position in 0..map_counts[source_map] {
                        let key = keys[source_base + source_position];
                        let timestamp = timestamps[source_base + source_position];
                        let mut target_position = 0;
                        while target_position < map_counts[target_map] && keys[target_base + target_position] != key {
                            target_position += 1;
                        }
                        if target_position == map_counts[target_map] {
                            if map_counts[target_map] >= MAX_KEYS { return -1; }
                            keys[target_base + target_position] = key;
                            timestamps[target_base + target_position] = timestamp;
                            map_counts[target_map] += 1;
                        } else if timestamp >= timestamps[target_base + target_position] {
                            timestamps[target_base + target_position] = timestamp;
                        }
                    }
                }
            }
        } else {
            return -1;
        }
    }
    lookup_mask
}
