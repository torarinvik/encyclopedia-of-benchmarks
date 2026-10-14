/// Jump search in an ascending sequence for the shared benchmark contract.
fn integer_sqrt(value: usize) -> usize {
    if value < 2 {
        return value;
    }
    let mut low = 1usize;
    let mut high = value / 2 + 1;
    let mut result = 1usize;
    while low <= high {
        let middle = low + (high - low) / 2;
        if middle <= value / middle {
            result = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    result
}

#[no_mangle]
pub extern "C" fn jump_search(values: *const i64, length: usize, target: i64) -> i64 {
    if length == 0 {
        return -1;
    }
    // The C caller guarantees a valid array of `length` elements.
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let step = integer_sqrt(length).max(1);
    let mut block_start = 0usize;
    let mut block_end = step.min(length);

    while values[block_end - 1] < target {
        if block_end == length {
            return -1;
        }
        block_start = block_end;
        block_end = if step > length - block_end { length } else { block_end + step };
    }

    for index in block_start..block_end {
        if values[index] == target {
            return index as i64;
        }
        if values[index] > target {
            return -1;
        }
    }
    -1
}
