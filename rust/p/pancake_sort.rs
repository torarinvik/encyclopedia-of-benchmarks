fn flip_prefix(values: &mut [i64], last_index: usize) {
    let mut first = 0usize;
    let mut last = last_index;
    while first < last {
        values.swap(first, last);
        first += 1;
        last -= 1;
    }
}

/// Pancake sort using prefix reversals for the shared sorting contract.
#[no_mangle]
pub extern "C" fn pancake_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    for prefix in (2..=length).rev() {
        let mut maximum = 0usize;
        for probe in 1..prefix {
            if values[probe] > values[maximum] {
                maximum = probe;
            }
        }
        if maximum != prefix - 1 {
            flip_prefix(values, maximum);
            flip_prefix(values, prefix - 1);
        }
    }
}
