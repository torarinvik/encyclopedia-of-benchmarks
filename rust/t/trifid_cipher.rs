const CODES: [&str; 27] = ["111","112","113","121","122","123","131","132","133","211","212","213","221","222","223","231","232","233","311","312","313","321","322","323","331","332","333"];

fn upper_ascii(c: i64) -> Option<u8> {
    if !(0..=127).contains(&c) { return None; }
    let b = c as u8;
    Some(if b.is_ascii_lowercase() { b - (b'a' - b'A') } else { b })
}

#[no_mangle]
pub unsafe extern "C" fn trifid_cipher(input: *const i64, length: usize,
                                           output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 31 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (mode, per, n, an) = (values[0], values[1], values[2], values[3]);
    if (mode != 0 && mode != 1) || !(1..=256).contains(&per) || !(0..=256).contains(&n) || an != 27 || length != 31 + n as usize { return -1; }
    let (period, n) = (per as usize, n as usize);
    let mut alphabet = Vec::with_capacity(27);
    for &v in &values[4+n..] {
        let Some(c) = upper_ascii(v) else { return -1; };
        if c == b' ' { continue; }
        if alphabet.contains(&c) { return -1; }
        alphabet.push(c);
    }
    if alphabet.len() != 27 { return -1; }
    let mut text = Vec::with_capacity(n);
    for &v in &values[4..4+n] {
        let Some(c) = upper_ascii(v) else { return -1; };
        if c == b' ' { continue; }
        if !alphabet.contains(&c) { return -1; }
        text.push(c);
    }
    let mut result = Vec::with_capacity(text.len());
    for block in text.chunks(period) {
        let k = block.len();
        if mode == 0 {
            let mut digits = Vec::with_capacity(3*k);
            for axis in 0..3 { for &c in block {
                let idx = alphabet.iter().position(|&x| x == c).unwrap();
                digits.push(CODES[idx].as_bytes()[axis]);
            }}
            for triple in digits.chunks_exact(3) {
                let idx = CODES.iter().position(|code| code.as_bytes() == triple).unwrap();
                result.push(alphabet[idx]);
            }
        } else {
            let mut digits = Vec::with_capacity(3*k);
            for &c in block {
                let idx = alphabet.iter().position(|&x| x == c).unwrap();
                digits.extend_from_slice(CODES[idx].as_bytes());
            }
            for i in 0..k {
                let triple = [digits[i], digits[k+i], digits[2*k+i]];
                let idx = CODES.iter().position(|code| code.as_bytes() == triple).unwrap();
                result.push(alphabet[idx]);
            }
        }
    }
    if output_capacity < result.len() { return -2; }
    if !result.is_empty() && output.is_null() { return -1; }
    if !result.is_empty() { std::ptr::copy_nonoverlapping(result.as_ptr(), output, result.len()); }
    result.len() as i64
}
