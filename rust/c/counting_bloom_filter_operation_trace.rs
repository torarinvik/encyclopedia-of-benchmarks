const MAX_OPERATIONS: usize = 64;
const MAX_PARSEABLE_LENGTH: usize = 130;
const COUNTER_COUNT: usize = 67;
const HASH_COUNT: usize = 4;

fn hash_positions(key: i64) -> [usize; HASH_COUNT] {
    let first = (17 * key + 3) % COUNTER_COUNT as i64;
    let step = 1 + ((5 * key + 3) % (COUNTER_COUNT as i64 - 1));
    let mut positions = [0usize; HASH_COUNT];
    for (index, position) in positions.iter_mut().enumerate() {
        *position = ((first + index as i64 * step) % COUNTER_COUNT as i64) as usize;
    }
    positions
}

#[no_mangle]
pub unsafe extern "C" fn counting_bloom_filter_operation_trace(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) {
        return -1;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let q_value = values[0];
    if q_value < 0 || q_value as usize > MAX_OPERATIONS {
        return -1;
    }
    let q = q_value as usize;
    if length != 1 + 2 * q {
        return -1;
    }
    for operation_index in 0..q {
        let opcode = values[1 + 2 * operation_index];
        let key = values[2 + 2 * operation_index];
        if !(0..=2).contains(&opcode) || !(0..=65535).contains(&key) {
            return -1;
        }
    }
    if output.is_null() || capacity < q {
        return -2;
    }

    let output_bytes = unsafe { core::slice::from_raw_parts_mut(output, q) };
    let mut counters = [0u8; COUNTER_COUNT];
    for operation_index in 0..q {
        let opcode = values[1 + 2 * operation_index];
        let key = values[2 + 2 * operation_index];
        let positions = hash_positions(key);
        if opcode == 0 {
            for position in positions {
                counters[position] += 1;
            }
            output_bytes[operation_index] = 1;
        } else if opcode == 1 {
            // The caller guarantees each deletion targets a live key.
            for position in positions {
                counters[position] -= 1;
            }
            output_bytes[operation_index] = 1;
        } else {
            output_bytes[operation_index] = u8::from(
                positions.iter().all(|&position| counters[position] != 0),
            );
        }
    }
    q as i64
}
