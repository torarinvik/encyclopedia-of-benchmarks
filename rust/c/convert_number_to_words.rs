const WORDS: [&str; 41] = ["zero","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety","quadrillion","trillion","billion","million","thousand","hundred","billiard","milliard","crore crore","lakh crore","crore","lakh","negative"];
fn scale_power(system: i64, index: usize) -> u64 {
    match system {
        0 => [1_000_000_000_000_000,1_000_000_000_000,1_000_000_000,1_000_000,1_000,100][index],
        1 => [1_000_000_000_000_000,1_000_000_000,1_000_000,1_000,100][index],
        _ => [100_000_000_000_000,1_000_000_000_000,10_000_000,100_000,1_000,100][index],
    }
}
fn scale_word(system: i64, index: usize) -> usize {
    match system { 0 => [28,29,30,31,32,33][index], 1 => [34,35,31,32,33][index], _ => [36,37,38,39,32,33][index] }
}
fn scale_count(system: i64) -> usize { if system == 1 { 5 } else { 6 } }
fn append_word(output: &mut Vec<u8>, id: usize, separate: bool) {
    if separate && !output.is_empty() { output.push(b' '); }
    output.extend_from_slice(WORDS[id].as_bytes());
}
fn append_small(n: u64, output: &mut Vec<u8>) {
    if n < 10 { append_word(output, n as usize, true); return; }
    if n < 20 { append_word(output, n as usize + 10, true); return; }
    append_word(output, (n / 10) as usize + 18, true);
    if n % 10 != 0 { output.push(b'-'); append_word(output, (n % 10) as usize, false); }
}
fn append_number(mut n: u64, system: i64, output: &mut Vec<u8>, depth: usize) {
    if depth > 8 { return; }
    let initial_len = output.len();
    for i in 0..scale_count(system) {
        let power = scale_power(system, i);
        let group = n / power;
        n %= power;
        if group == 0 { continue; }
        if group >= 100 { append_number(group, system, output, depth + 1); }
        else { append_small(group, output); }
        append_word(output, scale_word(system, i), true);
    }
    if n > 0 || output.len() == initial_len { append_small(n, output); }
}

#[no_mangle]
pub unsafe extern "C" fn convert_number_to_words(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let system = values[1];
    if !(0..=2).contains(&system) { return -1; }
    let number = values[0];
    let limit = if system == 0 { 999_999_999_999_999_999_i64 } else { 9_000_000_000_000_000_000_i64 };
    if number < -limit || number > limit { return -1; }
    let magnitude = number.unsigned_abs();
    let mut words = Vec::with_capacity(256);
    if number < 0 { append_word(&mut words, 40, true); }
    append_number(magnitude, system, &mut words, 0);
    if capacity < words.len() || output.is_null() { return -2; }
    std::slice::from_raw_parts_mut(output, words.len()).copy_from_slice(&words);
    words.len() as i64
}
