/// In-place cycle sort for signed 64-bit values.
#[no_mangle]
pub extern "C" fn cycle_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    for cycle_start in 0..(length - 1) {
        let mut item = values[cycle_start];
        let mut position = cycle_start;
        for scan in (cycle_start + 1)..length {
            if values[scan] < item {
                position += 1;
            }
        }
        if position == cycle_start {
            continue;
        }
        while position < length && item == values[position] {
            position += 1;
        }
        if position == length {
            continue;
        }
        std::mem::swap(&mut values[position], &mut item);
        while position != cycle_start {
            position = cycle_start;
            for scan in (cycle_start + 1)..length {
                if values[scan] < item {
                    position += 1;
                }
            }
            while position < length && item == values[position] {
                position += 1;
            }
            if position == length {
                break;
            }
            std::mem::swap(&mut values[position], &mut item);
        }
    }
}
