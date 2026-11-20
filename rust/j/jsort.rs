fn sift_down_min(values: &mut [i64], root_value: usize, end: usize) {
    let mut root = root_value;
    while root < end / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < end && values[child + 1] < values[child] {
            child += 1;
        }
        if values[root] <= values[child] {
            break;
        }
        values.swap(root, child);
        root = child;
    }
}

fn sift_down_max(values: &mut [i64], root_value: usize, end: usize) {
    let mut root = root_value;
    while root < end / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < end && values[child + 1] > values[child] {
            child += 1;
        }
        if values[root] >= values[child] {
            break;
        }
        values.swap(root, child);
        root = child;
    }
}

#[no_mangle]
pub unsafe extern "C" fn jsort(values: *mut i64, length: usize) {
    if values.is_null() || length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    for start in (0..length / 2).rev() {
        sift_down_min(values, start, length);
    }

    values.reverse();
    for start in (0..length / 2).rev() {
        sift_down_max(values, start, length);
    }
    values.reverse();

    for index in 1..length {
        let key = values[index];
        let mut position = index;
        while position > 0 && values[position - 1] > key {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = key;
    }
}
