const MAX_INPUT_LENGTH: usize = 16_384;

fn is_triangle_score(score: i64) -> bool {
    for n in 1..=100_i64 {
        if n * (n + 1) / 2 == score { return true; }
    }
    false
}

fn count_first_line(bytes: &[u8]) -> i64 {
    let line_end = bytes.iter().position(|&byte| byte == b'\r' || byte == b'\n').unwrap_or(bytes.len());
    let mut count = 0_i64;
    let mut token_start = 0_usize;
    for position in 0..=line_end {
        if position != line_end && bytes[position] != b',' { continue; }
        let mut start = token_start;
        let mut end = position;
        while start < end && bytes[start] == b'"' { start += 1; }
        while start < end && bytes[end - 1] == b'"' { end -= 1; }
        let mut score = 0_i64;
        for &byte in &bytes[start..end] { score += i64::from(byte) - 64; }
        if is_triangle_score(score) { count += 1; }
        token_start = position + 1;
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn solution42(input: *const i64, input_length: usize) -> i64 {
    if input_length > MAX_INPUT_LENGTH { return -1; }
    if input.is_null() {
        return if input_length == 0 { 0 } else { -1 };
    }
    let values = std::slice::from_raw_parts(input, input_length);
    for &value in values {
        if !(0..=127).contains(&value) { return -1; }
    }
    let mut bytes = [0_u8; MAX_INPUT_LENGTH];
    for (index, &value) in values.iter().enumerate() { bytes[index] = value as u8; }
    count_first_line(&bytes[..input_length])
}
