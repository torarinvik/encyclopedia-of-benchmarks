/// Unit-cost Levenshtein distance over two ASCII byte sequences.
#[no_mangle]
pub extern "C" fn levenshtein_distance(values: *const i64, length: usize) -> i64 {
    if length < 2 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (left_length, right_length) = (values[0], values[1]);
    if !(0..=255).contains(&left_length) || !(0..=255).contains(&right_length) {
        return -1;
    }
    let (left_length, right_length) = (left_length as usize, right_length as usize);
    if length != 2 + left_length + right_length {
        return -1;
    }
    let left = &values[2..2 + left_length];
    let right = &values[2 + left_length..];
    if left.iter().chain(right).any(|&byte| !(0..=127).contains(&byte)) {
        return -1;
    }

    let mut row = [0_i64; 256];
    for (column, value) in row.iter_mut().take(right_length + 1).enumerate() {
        *value = column as i64;
    }
    for row_index in 1..=left_length {
        let mut diagonal = row[0];
        row[0] = row_index as i64;
        for column in 1..=right_length {
            let above = row[column];
            let deletion = above + 1;
            let insertion = row[column - 1] + 1;
            let substitution = diagonal + i64::from(left[row_index - 1] != right[column - 1]);
            row[column] = deletion.min(insertion).min(substitution);
            diagonal = above;
        }
    }
    row[right_length]
}
