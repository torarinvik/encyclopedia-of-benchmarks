#[no_mangle]
pub unsafe extern "C" fn lipogram(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 1026 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=1024).contains(&values[0]) || length != values[0] as usize + 2 { return -1; }
    let mask = values[length - 1];
    if !(0..=67_108_863).contains(&mask) { return -1; }
    let n = values[0] as usize;
    let mut seen: u32 = 0;
    for &raw in &values[1..1 + n] {
        if !(0..=127).contains(&raw) { return -1; }
        let mut ch = raw as u8;
        if ch.is_ascii_uppercase() { ch = ch.to_ascii_lowercase(); }
        if ch.is_ascii_lowercase() {
            seen |= 1u32 << (ch - b'a');
        } else if !matches!(ch, b'\t' | b'\n' | 0x0b | 0x0c | b'\r' | b' ') {
            return -1;
        }
    }
    let missing = ((1u32 << 26) - 1) & !seen;
    if missing as i64 == mask { 1 } else { 0 }
}
