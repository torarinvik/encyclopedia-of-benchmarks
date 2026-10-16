const MAX_TEXT: usize = 256;
const MAX_KEY: usize = 32;

#[no_mangle]
pub unsafe extern "C" fn columnar_transposition(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let operation = values[0];
    let text_value = values[1];
    let raw_key_value = values[2];
    if (operation != 0 && operation != 1) || text_value < 0 || text_value > MAX_TEXT as i64 ||
        raw_key_value < 1 || raw_key_value > MAX_KEY as i64 { return -1; }
    let text_length = text_value as usize;
    let raw_key_length = raw_key_value as usize;
    if length != 3 + text_length + raw_key_length { return -1; }
    let text = &values[3..3 + text_length];
    let raw_key = &values[3 + text_length..];
    if text.iter().chain(raw_key.iter()).any(|&value| !(0..=127).contains(&value)) { return -1; }
    let key: Vec<u8> = raw_key.iter().filter_map(|&value| match value {
        65..=90 => Some(value as u8),
        97..=122 => Some((value - 32) as u8),
        _ => None,
    }).collect();
    if key.is_empty() { return -1; }
    let mut order: Vec<usize> = (0..key.len()).collect();
    order.sort_by_key(|&index| (key[index], index));
    if text_length == 0 { return 0; }
    if output.is_null() || capacity < text_length { return -2; }
    let output = std::slice::from_raw_parts_mut(output, text_length);
    let columns = key.len();
    let rows = (text_length + columns - 1) / columns;
    if operation == 0 {
        let mut written = 0;
        for &column in &order {
            for row in 0..rows {
                let index = row * columns + column;
                if index < text_length { output[written] = text[index] as u8; written += 1; }
            }
        }
        return written as i64;
    }
    let short_columns = text_length % columns;
    let lengths: Vec<usize> = (0..columns).map(|column|
        if short_columns == 0 || column < short_columns { rows } else { rows - 1 }).collect();
    let mut column_data: Vec<Vec<u8>> = lengths.iter().map(|&length| vec![0; length]).collect();
    let mut offset = 0;
    for &column in &order {
        for row in 0..lengths[column] { column_data[column][row] = text[offset] as u8; offset += 1; }
    }
    let mut written = 0;
    for row in 0..rows {
        for column in 0..columns {
            if row < lengths[column] { output[written] = column_data[column][row]; written += 1; }
        }
    }
    written as i64
}
