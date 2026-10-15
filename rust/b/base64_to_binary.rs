fn edge_space(value: i64) -> bool { (9..=13).contains(&value) || value == 32 }
fn digit(value: i64) -> i64 {
    if (65..=90).contains(&value) { return value - 65; }
    if (97..=122).contains(&value) { return value - 97 + 26; }
    if (48..=57).contains(&value) { return value - 48 + 52; }
    if value == 43 { return 62; }
    if value == 47 { return 63; }
    -1
}
#[no_mangle]
pub unsafe extern "C" fn base64_to_binary(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=256).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1..].iter().any(|v| !(0..=127).contains(v)) { return -1; }
    let mut begin = 0;
    let mut end = n;
    while begin < end && edge_space(values[1 + begin]) { begin += 1; }
    while end > begin && edge_space(values[end]) { end -= 1; }
    if begin == end { return -1; }
    let negative = values[1 + begin] == 45;
    if negative { begin += 1; }
    if values[1 + begin..1 + end].iter().any(|v| digit(*v) < 0) { return -1; }
    let output_length = (end - begin) * 6 + if negative { 1 } else { 0 };
    if capacity < output_length || output.is_null() { return -2; }
    let out = std::slice::from_raw_parts_mut(output, output_length);
    let mut offset = 0;
    if negative { out[offset] = b'-'; offset += 1; }
    for i in begin..end {
        let value = digit(values[1 + i]) as u8;
        for bit in (0..6).rev() { out[offset] = b'0' + ((value >> bit) & 1); offset += 1; }
    }
    output_length as i64
}
