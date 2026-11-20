const MAX_TEXT: usize = 64;
const SCRATCH: usize = 128;
const CODE_BYTES: usize = 10;

fn replace_all(text: &mut [u8; SCRATCH], length: &mut usize, old: &[u8], replacement: &[u8]) {
    let mut next = [0u8; SCRATCH];
    let mut out = 0usize;
    let mut at = 0usize;
    while at < *length {
        if at + old.len() <= *length && &text[at..at + old.len()] == old {
            for &byte in replacement { next[out] = byte; out += 1; }
            at += old.len();
        } else {
            next[out] = text[at]; out += 1; at += 1;
        }
    }
    text[..out].copy_from_slice(&next[..out]);
    *length = out;
}

fn replace_prefix(text: &mut [u8; SCRATCH], length: &mut usize, old: &[u8], replacement: &[u8]) {
    if *length < old.len() || &text[..old.len()] != old { return; }
    let tail = *length - old.len();
    text.copy_within(old.len()..*length, replacement.len());
    text[..replacement.len()].copy_from_slice(replacement);
    *length = replacement.len() + tail;
}

fn replace_suffix(text: &mut [u8; SCRATCH], length: &mut usize, old: &[u8], replacement: &[u8]) {
    if *length < old.len() { return; }
    let start = *length - old.len();
    if &text[start..*length] != old { return; }
    text[start..start + replacement.len()].copy_from_slice(replacement);
    *length = start + replacement.len();
}

fn replace_char(text: &mut [u8; SCRATCH], length: usize, old: u8, replacement: u8) {
    for byte in &mut text[..length] { if *byte == old { *byte = replacement; } }
}

fn squeeze(text: &mut [u8; SCRATCH], length: &mut usize, letter: u8, marker: u8) {
    let mut out = 0usize;
    for i in 0..*length {
        if text[i] == letter && out > 0 && text[out - 1] == marker { continue; }
        text[out] = if text[i] == letter { marker } else { text[i] };
        out += 1;
    }
    *length = out;
}

fn encode(values: *const i64) -> [u8; CODE_BYTES] {
    let mut text = [0u8; SCRATCH];
    let mut n = unsafe { *values as usize };
    for i in 0..n {
        let code = unsafe { *values.add(i + 1) as u8 };
        text[i] = if code.is_ascii_uppercase() { code + 32 } else { code };
    }
    if n == 0 { return *b"1111111111"; }
    if text[n - 1] == b'e' { n -= 1; }
    replace_prefix(&mut text, &mut n, b"cough", b"cou2f");
    replace_prefix(&mut text, &mut n, b"rough", b"rou2f");
    replace_prefix(&mut text, &mut n, b"tough", b"tou2f");
    replace_prefix(&mut text, &mut n, b"enough", b"enou2f");
    replace_prefix(&mut text, &mut n, b"trough", b"trou2f");
    replace_prefix(&mut text, &mut n, b"gn", b"2n");
    replace_suffix(&mut text, &mut n, b"mb", b"m2");
    replace_all(&mut text, &mut n, b"cq", b"2q"); replace_all(&mut text, &mut n, b"ci", b"si");
    replace_all(&mut text, &mut n, b"ce", b"se"); replace_all(&mut text, &mut n, b"cy", b"sy");
    replace_all(&mut text, &mut n, b"tch", b"2ch");
    replace_char(&mut text, n, b'c', b'k'); replace_char(&mut text, n, b'q', b'k');
    replace_char(&mut text, n, b'x', b'k'); replace_char(&mut text, n, b'v', b'f');
    replace_all(&mut text, &mut n, b"dg", b"2g"); replace_all(&mut text, &mut n, b"tio", b"sio");
    replace_all(&mut text, &mut n, b"tia", b"sia"); replace_char(&mut text, n, b'd', b't');
    replace_all(&mut text, &mut n, b"ph", b"fh"); replace_char(&mut text, n, b'b', b'p');
    replace_all(&mut text, &mut n, b"sh", b"s2"); replace_char(&mut text, n, b'z', b's');
    if n > 0 && matches!(text[0], b'a' | b'e' | b'i' | b'o' | b'u') { text[0] = b'A'; }
    for byte in &mut text[..n] { if matches!(*byte, b'a' | b'e' | b'i' | b'o' | b'u') { *byte = b'3'; } }
    replace_char(&mut text, n, b'j', b'y');
    replace_prefix(&mut text, &mut n, b"y3", b"Y3"); replace_prefix(&mut text, &mut n, b"y", b"A");
    replace_char(&mut text, n, b'y', b'3');
    replace_all(&mut text, &mut n, b"3gh3", b"3kh3"); replace_all(&mut text, &mut n, b"gh", b"22");
    replace_char(&mut text, n, b'g', b'k');
    squeeze(&mut text, &mut n, b's', b'S'); squeeze(&mut text, &mut n, b't', b'T'); squeeze(&mut text, &mut n, b'p', b'P');
    squeeze(&mut text, &mut n, b'k', b'K'); squeeze(&mut text, &mut n, b'f', b'F'); squeeze(&mut text, &mut n, b'm', b'M'); squeeze(&mut text, &mut n, b'n', b'N');
    replace_all(&mut text, &mut n, b"w3", b"W3"); replace_all(&mut text, &mut n, b"wh3", b"Wh3");
    replace_suffix(&mut text, &mut n, b"w", b"3"); replace_char(&mut text, n, b'w', b'2');
    replace_prefix(&mut text, &mut n, b"h", b"A"); replace_char(&mut text, n, b'h', b'2');
    replace_all(&mut text, &mut n, b"r3", b"R3"); replace_suffix(&mut text, &mut n, b"r", b"3"); replace_char(&mut text, n, b'r', b'2');
    replace_all(&mut text, &mut n, b"l3", b"L3"); replace_suffix(&mut text, &mut n, b"l", b"3"); replace_char(&mut text, n, b'l', b'2');
    let mut out = 0usize;
    for i in 0..n { if text[i] != b'2' { text[out] = text[i]; out += 1; } }
    n = out;
    replace_suffix(&mut text, &mut n, b"3", b"A");
    out = 0;
    for i in 0..n { if text[i] != b'3' { text[out] = text[i]; out += 1; } }
    let mut result = [b'1'; CODE_BYTES];
    result[..out.min(CODE_BYTES)].copy_from_slice(&text[..out.min(CODE_BYTES)]);
    result
}

#[no_mangle]
pub unsafe extern "C" fn caverphone_2_encoder(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || !(1..=MAX_TEXT + 1).contains(&length) { return -1; }
    let count = *values;
    if !(0..=MAX_TEXT as i64).contains(&count) || length != count as usize + 1 { return -1; }
    for i in 0..count as usize {
        let code = *values.add(i + 1);
        if !((65..=90).contains(&code) || (97..=122).contains(&code)) { return -1; }
    }
    if output.is_null() || output_capacity < CODE_BYTES { return -2; }
    let result = encode(values);
    for i in 0..CODE_BYTES { *output.add(i) = result[i]; }
    CODE_BYTES as i64
}
