/// Return the source-style English letter-frequency match score for ASCII bytes.
#[no_mangle]
pub unsafe extern "C" fn frequency_finder(input: *const i64, length: usize) -> i64 {
    const ETAOIN: &[u8; 26] = b"ETAOINSHRDLCUMWFGYPBVKJXQZ";
    if input.is_null() { return if length == 0 { 0 } else { -1 }; }
    if length > 1024 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut counts = [0i64; 26];
    for &raw in values {
        if !(0..=127).contains(&raw) { return -1; }
        let mut b = raw as u8;
        if b.is_ascii_lowercase() { b -= 32; }
        if b.is_ascii_uppercase() { counts[(b - b'A') as usize] += 1; }
    }
    let mut order = [0usize; 26];
    for (i, item) in order.iter_mut().enumerate() { *item = i; }
    order.sort_by(|&a, &b| counts[b].cmp(&counts[a]).then_with(|| {
        let ar = ETAOIN.iter().position(|&c| c == b'A' + a as u8).unwrap();
        let br = ETAOIN.iter().position(|&c| c == b'A' + b as u8).unwrap();
        br.cmp(&ar)
    }));
    let mut score = 0;
    for i in 0..6 {
        if ETAOIN[..6].contains(&(b'A' + order[i] as u8)) { score += 1; }
        if ETAOIN[20..].contains(&(b'A' + order[20 + i] as u8)) { score += 1; }
    }
    score
}
