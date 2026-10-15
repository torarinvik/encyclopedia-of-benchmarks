const INVALID_RESULT: i64 = -1;
const CAPACITY_RESULT: i64 = -2;

fn hex_value(value: i64) -> Option<u8> {
    match value {
        48..=57 => Some((value - 48) as u8),
        65..=70 => Some((value - 65 + 10) as u8),
        97..=102 => Some((value - 97 + 10) as u8),
        _ => None,
    }
}

#[no_mangle]
pub unsafe extern "C" fn hex_to_binary(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if length > 256 || (length != 0 && values.is_null()) {
        return INVALID_RESULT;
    }
    for index in 0..length {
        if hex_value(*values.add(index)).is_none() {
            return INVALID_RESULT;
        }
    }

    let required = length * 4;
    if output.is_null() || capacity < required {
        return CAPACITY_RESULT;
    }
    for index in 0..length {
        let digit = hex_value(*values.add(index)).unwrap();
        for bit in 0..4 {
            *output.add(index * 4 + bit) = if ((digit >> (3 - bit)) & 1) == 1 { b'1' } else { b'0' };
        }
    }
    required as i64
}
