const MAX_PLAINTEXT: usize = 256;
const MAX_CIPHERTEXT: usize = 512;
const MAX_KEY: usize = 16;
const MAX_ROWS: usize = 512;
const LABELS: &[u8; 6] = b"ADFGVX";
const SQUARE: &[u8; 36] = b"NA1C3H8TB2OME5WRPD4F6G7I9J0KLQSUVXYZ";

fn polybius_cell(value: u8) -> Option<usize> {
    SQUARE.iter().position(|&cell| cell == value)
}

fn label_index(value: u8) -> Option<usize> {
    LABELS.iter().position(|&label| label == value)
}

#[no_mangle]
pub unsafe extern "C" fn adfgvxcipher(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let mode = *input;
    let text_length_value = *input.add(1);
    let key_length_value = *input.add(2);
    if (mode != 0 && mode != 1) || text_length_value < 0 || key_length_value < 1 || key_length_value > MAX_KEY as i64 {
        return -1;
    }
    let text_length = text_length_value as usize;
    let key_length = key_length_value as usize;
    if (mode == 0 && text_length > MAX_PLAINTEXT) || (mode == 1 && text_length > MAX_CIPHERTEXT)
        || length != 3 + text_length + key_length { return -1; }
    for index in 0..text_length {
        let value = *input.add(3 + index);
        if !(0..=127).contains(&value) { return -1; }
        if mode == 1 && label_index(value as u8).is_none() { return -1; }
    }
    if mode == 1 && text_length % 2 != 0 { return -1; }
    let key_start = 3 + text_length;
    for index in 0..key_length {
        let value = *input.add(key_start + index);
        if !(b'A' as i64..=b'Z' as i64).contains(&value) { return -1; }
        for previous in 0..index {
            if value == *input.add(key_start + previous) { return -1; }
        }
    }

    let mut order = [0usize; MAX_KEY];
    for index in 0..key_length { order[index] = index; }
    for index in 1..key_length {
        let current = order[index];
        let mut position = index;
        while position > 0 && *input.add(key_start + order[position - 1]) > *input.add(key_start + current) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }

    let mut result = [0u8; MAX_CIPHERTEXT];
    let mut result_length = 0usize;
    if mode == 0 {
        let mut fractionated = [0u8; MAX_CIPHERTEXT];
        let mut fractionated_length = 0usize;
        for index in 0..text_length {
            let mut value = (*input.add(3 + index)) as u8;
            if value.is_ascii_lowercase() { value = value.to_ascii_uppercase(); }
            if !value.is_ascii_alphanumeric() { continue; }
            let cell = match polybius_cell(value) { Some(cell) => cell, None => return -1 };
            fractionated[fractionated_length] = LABELS[cell / 6];
            fractionated[fractionated_length + 1] = LABELS[cell % 6];
            fractionated_length += 2;
        }
        let rows = (fractionated_length + key_length - 1) / key_length;
        let mut table = [b'_'; MAX_ROWS * MAX_KEY];
        for index in 0..fractionated_length {
            table[(index / key_length) * MAX_KEY + index % key_length] = fractionated[index];
        }
        for order_index in 0..key_length {
            let column = order[order_index];
            for row in 0..rows {
                let value = table[row * MAX_KEY + column];
                if value != b'_' { result[result_length] = value; result_length += 1; }
            }
        }
    } else {
        let rows = (text_length + key_length - 1) / key_length;
        let mut table = [0u8; MAX_ROWS * MAX_KEY];
        let mut source_index = 0usize;
        for order_index in 0..key_length {
            let column = order[order_index];
            for row in 0..rows {
                table[row * MAX_KEY + column] = if source_index < text_length {
                    let value = *input.add(3 + source_index) as u8;
                    source_index += 1;
                    value
                } else { b'_' };
            }
        }
        let mut fractionated = [0u8; MAX_CIPHERTEXT];
        let mut fractionated_length = 0usize;
        for row in 0..rows {
            for column in 0..key_length {
                let value = table[row * MAX_KEY + column];
                if value != b'_' { fractionated[fractionated_length] = value; fractionated_length += 1; }
            }
        }
        for index in (0..fractionated_length).step_by(2) {
            let row = match label_index(fractionated[index]) { Some(value) => value, None => return -1 };
            let column = match label_index(fractionated[index + 1]) { Some(value) => value, None => return -1 };
            result[result_length] = SQUARE[row * 6 + column];
            result_length += 1;
        }
    }
    if output_capacity < result_length || (result_length != 0 && output.is_null()) { return -2; }
    if result_length != 0 { core::ptr::copy_nonoverlapping(result.as_ptr(), output, result_length); }
    result_length as i64
}
