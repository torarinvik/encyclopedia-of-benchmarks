#[no_mangle]
pub unsafe extern "C" fn cyclic_sort(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    const MAX_LENGTH: usize = 1024;
    if length > MAX_LENGTH || (length > 0 && values.is_null()) {
        return -1;
    }
    let mut seen = [false; MAX_LENGTH + 1];
    for index in 0..length {
        let value = *values.add(index);
        if value < 1 || value > length as i64 || seen[value as usize] {
            return -1;
        }
        seen[value as usize] = true;
    }

    let mut sorted = [0i64; MAX_LENGTH];
    for index in 0..length {
        sorted[index] = *values.add(index);
    }
    let mut index = 0;
    while index < length {
        let destination = (sorted[index] - 1) as usize;
        if destination == index {
            index += 1;
        } else {
            sorted.swap(index, destination);
        }
    }

    let output_length = length * 8;
    if output_length > output_capacity || (output_length > 0 && output.is_null()) {
        return -2;
    }
    for item in 0..length {
        let bits = sorted[item] as u64;
        for byte in 0..8 {
            *output.add(item * 8 + byte) = (bits >> (byte * 8)) as u8;
        }
    }
    length as i64
}
