const INVALID_RESULT: i64 = -1;
const CAPACITY_ERROR: i64 = -2;

fn token_length(value: i64) -> usize {
    if value % 15 == 0 { 8 }
    else if value % 3 == 0 || value % 5 == 0 { 4 }
    else if value >= 100 { 3 }
    else if value >= 10 { 2 }
    else { 1 }
}

fn append_number(value_value: i64, output: &mut [u8], position_value: usize) -> usize {
    let mut value = value_value;
    let mut position = position_value;
    if value >= 100 {
        output[position] = b'0' + (value / 100) as u8;
        position += 1;
        value %= 100;
        output[position] = b'0' + (value / 10) as u8;
        position += 1;
        output[position] = b'0' + (value % 10) as u8;
        position += 1;
    } else if value >= 10 {
        output[position] = b'0' + (value / 10) as u8;
        position += 1;
        output[position] = b'0' + (value % 10) as u8;
        position += 1;
    } else {
        output[position] = b'0' + value as u8;
        position += 1;
    }
    position
}

#[no_mangle]
pub unsafe extern "C" fn fizz_buzz(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=512).contains(&value) { return INVALID_RESULT; }
    let mut width = 0usize;
    for current in 1..=value { width += token_length(current) + 1; }
    if output.is_null() || output_capacity < width { return CAPACITY_ERROR; }
    let bytes = std::slice::from_raw_parts_mut(output, output_capacity);
    let mut position = 0usize;
    for current in 1..=value {
        if current % 15 == 0 {
            bytes[position..position + 8].copy_from_slice(b"FizzBuzz");
            position += 8;
        } else if current % 3 == 0 {
            bytes[position..position + 4].copy_from_slice(b"Fizz");
            position += 4;
        } else if current % 5 == 0 {
            bytes[position..position + 4].copy_from_slice(b"Buzz");
            position += 4;
        } else {
            position = append_number(current, bytes, position);
        }
        bytes[position] = b' ';
        position += 1;
    }
    position as i64
}
