fn random_pivot_quick_sort_next31(state: &mut u64) -> u64 {
    *state = (*state * 48_271) % 2_147_483_647;
    *state
}

fn random_pivot_quick_sort_next(state: &mut u64) -> u64 {
    let high = random_pivot_quick_sort_next31(state);
    let low = random_pivot_quick_sort_next31(state);
    high * 2_147_483_647 + low
}

fn random_pivot_quick_sort_partition(values: &mut [i64], low: usize, high: usize, state: &mut u64) -> usize {
    let width = high - low;
    let pivot_index = low + (random_pivot_quick_sort_next(state) % width as u64) as usize;
    let pivot_value = values[pivot_index];
    values.swap(pivot_index, high - 1);
    let mut boundary = low;
    for scan in low..high - 1 {
        if values[scan] < pivot_value {
            values.swap(boundary, scan);
            boundary += 1;
        }
    }
    values.swap(boundary, high - 1);
    boundary
}

/// Quicksort with a reproducible pseudorandom pivot stream.
#[no_mangle]
pub extern "C" fn random_pivot_quick_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let mut stack_low = [0usize; 128];
    let mut stack_high = [0usize; 128];
    let mut stack_size = 0usize;
    let mut low = 0usize;
    let mut high = length;
    let mut random_state = 1u64;
    loop {
        while high - low > 1 {
            let pivot = random_pivot_quick_sort_partition(values, low, high, &mut random_state);
            let left_size = pivot - low;
            let right_size = high - pivot - 1;
            if left_size < right_size {
                if right_size > 1 {
                    stack_low[stack_size] = pivot + 1;
                    stack_high[stack_size] = high;
                    stack_size += 1;
                }
                high = pivot;
            } else {
                if left_size > 1 {
                    stack_low[stack_size] = low;
                    stack_high[stack_size] = pivot;
                    stack_size += 1;
                }
                low = pivot + 1;
            }
        }
        if stack_size == 0 {
            break;
        }
        stack_size -= 1;
        low = stack_low[stack_size];
        high = stack_high[stack_size];
    }
}
