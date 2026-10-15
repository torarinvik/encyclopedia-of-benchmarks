/// Fixed-square Bifid fractionation over one complete message block.
fn letter_index(value: i64, merge_j: bool) -> Option<usize> {
    let normalized = if (97..=122).contains(&value) { value - 32 } else { value };
    if !(65..=90).contains(&normalized) { return None; }
    let mut index = (normalized - 65) as usize;
    if index == 9 {
        if !merge_j { return None; }
        index = 8;
    } else if index > 9 {
        index -= 1;
    }
    Some(index)
}

fn letter_for_index(index: usize) -> u8 {
    b'a' + index as u8 + u8::from(index >= 9)
}

#[no_mangle]
pub unsafe extern "C" fn bifid_cipher(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 258 { return -1; }
    let mode = *input;
    let text_length_value = *input.add(1);
    if (mode != 0 && mode != 1) || !(0..=256).contains(&text_length_value) { return -1; }
    let text_length = text_length_value as usize;
    if length != text_length + 2 { return -1; }
    let text = std::slice::from_raw_parts(input.add(2), text_length);

    let mut rows = [0u8; 256];
    let mut columns = [0u8; 256];
    let mut coordinates = [0u8; 512];
    let mut result = [0u8; 256];
    let mut result_length = 0usize;

    if mode == 0 {
        for &value in text {
            if value == b' ' as i64 { continue; }
            let index = match letter_index(value, true) { Some(index) => index, None => return -1 };
            rows[result_length] = (index / 5 + 1) as u8;
            columns[result_length] = (index % 5 + 1) as u8;
            result_length += 1;
        }
        for i in 0..result_length {
            coordinates[i] = rows[i];
            coordinates[result_length + i] = columns[i];
        }
        for i in 0..result_length {
            let row = (coordinates[2 * i] - 1) as usize;
            let column = (coordinates[2 * i + 1] - 1) as usize;
            result[i] = letter_for_index(row * 5 + column);
        }
    } else {
        result_length = text_length;
        for (i, &value) in text.iter().enumerate() {
            let index = match letter_index(value, false) { Some(index) => index, None => return -1 };
            coordinates[2 * i] = (index / 5 + 1) as u8;
            coordinates[2 * i + 1] = (index % 5 + 1) as u8;
        }
        for i in 0..result_length {
            let row = (coordinates[i] - 1) as usize;
            let column = (coordinates[result_length + i] - 1) as usize;
            result[i] = letter_for_index(row * 5 + column);
        }
    }

    if output_capacity < result_length || (result_length != 0 && output.is_null()) { return -2; }
    for i in 0..result_length {
        *output.add(i) = result[i];
    }
    result_length as i64
}
