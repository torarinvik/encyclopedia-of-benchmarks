/// Stable bottom-up TimSort-style sort using caller-provided scratch storage.
const TIM_SORT_RUN: usize = 32;

fn insertion_sort_run(values: &mut [i64]) {
    for index in 1..values.len() {
        let key = values[index];
        let mut cursor = index;
        while cursor > 0 && values[cursor - 1] > key {
            values[cursor] = values[cursor - 1];
            cursor -= 1;
        }
        values[cursor] = key;
    }
}

fn merge_runs(values: &mut [i64], scratch: &mut [i64], left: usize, middle: usize, right: usize) {
    scratch[left..right].copy_from_slice(&values[left..right]);
    let mut first = left;
    let mut second = middle;
    for output in left..right {
        if first == middle {
            values[output] = scratch[second];
            second += 1;
        } else if second == right || scratch[first] <= scratch[second] {
            values[output] = scratch[first];
            first += 1;
        } else {
            values[output] = scratch[second];
            second += 1;
        }
    }
}

fn tim_sort_impl(values: &mut [i64], scratch: &mut [i64]) {
    if values.len() < 2 {
        return;
    }
    let length = values.len();
    let mut start = 0;
    while start < length {
        let remaining = length - start;
        let ending = if remaining < TIM_SORT_RUN { length } else { start + TIM_SORT_RUN };
        insertion_sort_run(&mut values[start..ending]);
        start = ending;
    }

    let mut width = TIM_SORT_RUN;
    while width < length {
        let mut left = 0;
        while left < length {
            let left_remaining = length - left;
            let middle = left + width.min(left_remaining);
            let right_remaining = length - middle;
            let right = middle + width.min(right_remaining);
            if middle < right {
                merge_runs(values, scratch, left, middle, right);
            }
            left = right;
        }
        if width >= length - width {
            break;
        }
        width *= 2;
    }
}

#[no_mangle]
pub extern "C" fn tim_sort(values: *mut i64, scratch: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let scratch = unsafe { std::slice::from_raw_parts_mut(scratch, length) };
    tim_sort_impl(values, scratch);
}
