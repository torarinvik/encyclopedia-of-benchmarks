const MAX_INTERVALS: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_INTERVALS;

fn store_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        unsafe { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn merge_intervals(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    let raw_count = input[0];
    if raw_count < 0
        || raw_count > MAX_INTERVALS as i64
        || length != 1 + 2 * raw_count as usize
    {
        return -1;
    }

    let count = raw_count as usize;
    let mut intervals = [(0i32, 0i32); MAX_INTERVALS];
    for index in 0..count {
        let start = input[1 + 2 * index];
        let end = input[2 + 2 * index];
        if start < i32::MIN as i64
            || start > i32::MAX as i64
            || end < i32::MIN as i64
            || end > i32::MAX as i64
            || start > end
        {
            return -1;
        }
        intervals[index] = (start as i32, end as i32);
    }

    intervals[..count].sort_unstable_by_key(|interval| interval.0);
    let mut merged = 0usize;
    for index in 0..count {
        let (start, end) = intervals[index];
        if merged != 0 && start <= intervals[merged - 1].1 {
            if end > intervals[merged - 1].1 {
                intervals[merged - 1].1 = end;
            }
        } else {
            intervals[merged] = (start, end);
            merged += 1;
        }
    }

    let byte_count = 8 * merged;
    if output.is_null() || capacity < byte_count {
        return -2;
    }
    for index in 0..merged {
        store_i32_le(output, 8 * index, intervals[index].0);
        store_i32_le(output, 8 * index + 4, intervals[index].1);
    }
    byte_count as i64
}
