const QUEUE_CAPACITY: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 65;
const VALUE_MIN: i64 = -1000;
const VALUE_MAX: i64 = 1000;
const CHECKSUM_OFFSET: i64 = 1001;

#[no_mangle]
pub unsafe extern "C" fn minimum_queue_two_stacks(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > 32 {
        return -1;
    }

    let mut in_values = [0_i64; QUEUE_CAPACITY];
    let mut in_minimums = [0_i64; QUEUE_CAPACITY];
    let mut out_values = [0_i64; QUEUE_CAPACITY];
    let mut out_minimums = [0_i64; QUEUE_CAPACITY];
    let mut in_count = 0_usize;
    let mut out_count = 0_usize;
    let mut cursor = 1_usize;
    let operation_count = values[0] as usize;
    let mut checksum = 0_i64;

    for operation in 0..operation_count {
        if cursor >= length {
            return -1;
        }
        let opcode = values[cursor];
        cursor += 1;
        if opcode == 0 {
            if cursor >= length {
                return -1;
            }
            let value = values[cursor];
            cursor += 1;
            if !(VALUE_MIN..=VALUE_MAX).contains(&value)
                || in_count + out_count >= QUEUE_CAPACITY
            {
                return -1;
            }
            in_values[in_count] = value;
            in_minimums[in_count] = if in_count == 0 {
                value
            } else {
                value.min(in_minimums[in_count - 1])
            };
            in_count += 1;
        } else if opcode == 1 {
            if in_count + out_count == 0 {
                return -1;
            }
            if out_count == 0 {
                while in_count > 0 {
                    in_count -= 1;
                    let value = in_values[in_count];
                    out_values[out_count] = value;
                    out_minimums[out_count] = if out_count == 0 {
                        value
                    } else {
                        value.min(out_minimums[out_count - 1])
                    };
                    out_count += 1;
                }
            }
            out_count -= 1;
            checksum += (operation as i64 + 1) * (out_values[out_count] + CHECKSUM_OFFSET);
        } else if opcode == 2 {
            if in_count + out_count == 0 {
                return -1;
            }
            let observed = if in_count == 0 {
                out_minimums[out_count - 1]
            } else if out_count == 0 {
                in_minimums[in_count - 1]
            } else {
                in_minimums[in_count - 1].min(out_minimums[out_count - 1])
            };
            checksum += (operation as i64 + 1) * (observed + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    if cursor != length {
        return -1;
    }

    let mut position = 0_i64;
    for index in (0..out_count).rev() {
        position += 1;
        checksum += position * (out_values[index] + CHECKSUM_OFFSET);
    }
    for index in 0..in_count {
        position += 1;
        checksum += position * (in_values[index] + CHECKSUM_OFFSET);
    }
    checksum
}
