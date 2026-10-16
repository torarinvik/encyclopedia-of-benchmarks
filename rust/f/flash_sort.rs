/// Bounded Flash Sort followed by the source's insertion-sort finishing pass.
const MAX_LENGTH: usize = 64;

fn valid_length(length: usize) -> bool { length <= 1 || (length >= 3 && length <= MAX_LENGTH) }
fn class_of(value: i64, minimum: i64, range: i64, classes: usize) -> usize {
    ((classes as i64 - 1) * (value - minimum) / range) as usize
}
fn flash_sort_values(values: &mut [i64; MAX_LENGTH], length: usize) -> bool {
    if length <= 1 { return true; }
    let mut minimum = values[0];
    let mut maximum = values[0];
    for &value in &values[1..length] {
        if value < minimum { minimum = value; }
        if value > maximum { maximum = value; }
    }
    if minimum == maximum { return true; }
    let range = maximum - minimum;
    let classes = (9 * length / 20).max(1);
    let mut class_ends = [0usize; MAX_LENGTH];
    for &value in &values[..length] { class_ends[class_of(value, minimum, range, classes)] += 1; }
    for index in 1..classes { class_ends[index] += class_ends[index - 1]; }
    let (mut moves, mut j, mut k) = (0usize, 0usize, classes - 1);
    while moves < length - 1 {
        while j > class_ends[k] - 1 {
            j += 1;
            if j >= length { return false; }
            k = class_of(values[j], minimum, range, classes);
        }
        let mut flash = values[j];
        while j != class_ends[k] {
            k = class_of(flash, minimum, range, classes);
            class_ends[k] -= 1;
            let target = class_ends[k];
            let hold = values[target];
            values[target] = flash;
            flash = hold;
            moves += 1;
        }
    }
    for index in 1..length {
        let key = values[index];
        let mut cursor = index;
        while cursor > 0 && values[cursor - 1] > key {
            values[cursor] = values[cursor - 1];
            cursor -= 1;
        }
        values[cursor] = key;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn flash_sort(input: *const i64, length: usize,
                                     output: *mut u8, output_capacity: usize) -> i64 {
    if length > 65 || !valid_length(length) || (length != 0 && input.is_null()) { return -1; }
    let mut values = [0i64; MAX_LENGTH];
    for index in 0..length {
        let value = *input.add(index);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
        values[index] = value;
    }
    let output_bytes = length * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    if !flash_sort_values(&mut values, length) { return -1; }
    for index in 0..length {
        let bits = values[index] as u32;
        for byte in 0..4 { *output.add(index * 4 + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
