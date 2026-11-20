fn insertion_sort(values: &mut [i64]) {
    for index in 1..values.len() {
        let key = values[index];
        let mut position = index;
        while position > 0 && values[position - 1] > key {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = key;
    }
}

#[no_mangle]
pub unsafe extern "C" fn linear_probing_sort(values: *mut i64, length: usize) {
    if values.is_null() || length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    if length > 1024 || values.iter().any(|&value| !(0..=255).contains(&value)) {
        insertion_sort(values);
        return;
    }

    let minimum = *values.iter().min().unwrap();
    let maximum = *values.iter().max().unwrap();
    let main_slots = 256 * (length + 1) + 1;
    let table_length = main_slots + length;
    let mut table = Vec::new();
    if table.try_reserve_exact(table_length).is_err() {
        insertion_sort(values);
        return;
    }
    table.resize(table_length, 0i64);

    let span = maximum - minimum;
    for &value in values.iter() {
        let home = if span == 0 {
            0
        } else {
            ((value - minimum) as usize) * (main_slots - 1) / span as usize
        };
        let mut slot = home;
        while table[slot] != 0 {
            slot += 1;
        }
        table[slot] = value + 1;
    }
    let mut output = 0;
    for entry in table.into_iter().filter(|&entry| entry != 0) {
        values[output] = entry - 1;
        output += 1;
    }
}
