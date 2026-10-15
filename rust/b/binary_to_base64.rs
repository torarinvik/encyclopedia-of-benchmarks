const ALPHABET: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
fn edge_space(value: i64) -> bool { (9..=13).contains(&value) || value == 32 }

#[no_mangle]
pub unsafe extern "C" fn binary_to_base64(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=256).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1..].iter().any(|v| !(0..=127).contains(v)) { return -1; }
    let mut begin = 0;
    let mut end = n;
    while begin < end && edge_space(values[1 + begin]) { begin += 1; }
    while end > begin && edge_space(values[end]) { end -= 1; }
    if begin == end { return -1; }
    let negative = values[1 + begin] == b'-' as i64;
    if negative { begin += 1; }
    if values[1 + begin..1 + end].iter().any(|v| *v != b'0' as i64 && *v != b'1' as i64) { return -1; }
    let bit_count = end - begin;
    let padding = 6 - bit_count % 6;
    let groups = (bit_count + padding) / 6;
    let output_length = groups + if negative { 1 } else { 0 };
    if capacity < output_length || output.is_null() { return -2; }
    let out = std::slice::from_raw_parts_mut(output, output_length);
    let mut offset = 0;
    if negative { out[offset] = b'-'; offset += 1; }
    for group in 0..groups {
        let mut value = 0usize;
        for bit in 0..6 {
            value <<= 1;
            let position = group * 6 + bit;
            if position >= padding && values[1 + begin + position - padding] == b'1' as i64 { value += 1; }
        }
        out[offset] = ALPHABET[value];
        offset += 1;
    }
    output_length as i64
}
