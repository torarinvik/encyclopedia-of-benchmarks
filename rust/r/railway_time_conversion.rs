const MAX_INPUT_LENGTH: usize = 10;
const PACKED_INPUT_LENGTH: usize = MAX_INPUT_LENGTH + 1;
const OUTPUT_LENGTH: usize = 8;

fn is_digit(value: i64) -> bool {
    (48..=57).contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn railway_time_conversion(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length != PACKED_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] != MAX_INPUT_LENGTH as i64 {
        return -1;
    }

    if input[3] != 58 || input[6] != 58 ||
        !((input[9] == 65 && input[10] == 77) ||
          (input[9] == 80 && input[10] == 77)) ||
        !is_digit(input[1]) || !is_digit(input[2]) ||
        !is_digit(input[4]) || !is_digit(input[5]) ||
        !is_digit(input[7]) || !is_digit(input[8]) {
        return -1;
    }

    let hour = (input[1] - 48) * 10 + input[2] - 48;
    let minute = (input[4] - 48) * 10 + input[5] - 48;
    let second = (input[7] - 48) * 10 + input[8] - 48;
    if !(1..=12).contains(&hour) || minute > 59 || second > 59 {
        return -1;
    }
    if output.is_null() || output_capacity < OUTPUT_LENGTH {
        return -2;
    }

    let hour24 = hour % 12 + if input[9] == 80 { 12 } else { 0 };
    let bytes = [
        (48 + hour24 / 10) as u8,
        (48 + hour24 % 10) as u8,
        58,
        input[4] as u8,
        input[5] as u8,
        58,
        input[7] as u8,
        input[8] as u8,
    ];
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, OUTPUT_LENGTH);
    OUTPUT_LENGTH as i64
}
