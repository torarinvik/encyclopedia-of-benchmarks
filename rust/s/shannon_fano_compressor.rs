const MAX_TEXT: usize = 16;
const MAX_SYMBOLS: usize = 16;
const MAX_CODE: usize = 15;
const MAX_OUTPUT: usize = 514;

type Codes = [[u8; MAX_CODE]; 128];
type Lengths = [u8; 128];

fn make_codes(symbols: &[u8], freq: &[f64; 128], prefix: &mut [u8; MAX_CODE], depth: usize,
              codes: &mut Codes, lengths: &mut Lengths) -> bool {
    if symbols.len() == 1 {
        let s = symbols[0] as usize;
        codes[s][..depth].copy_from_slice(&prefix[..depth]);
        lengths[s] = depth as u8;
        return true;
    }
    let mut total = 0.0;
    for &s in symbols { total += freq[s as usize]; }
    let capacity = 0.5 * total;
    let mut running = 0.0;
    let mut left = [0u8; MAX_SYMBOLS];
    let mut right = [0u8; MAX_SYMBOLS];
    let (mut nl, mut nr) = (0usize, 0usize);
    for &s in symbols {
        let f = freq[s as usize];
        if running + f <= capacity { left[nl] = s; nl += 1; running += f; }
        else { right[nr] = s; nr += 1; }
    }
    if nl == 0 || nr == 0 || depth >= MAX_CODE { return false; }
    prefix[depth] = b'0';
    if !make_codes(&left[..nl], freq, prefix, depth + 1, codes, lengths) { return false; }
    prefix[depth] = b'1';
    make_codes(&right[..nr], freq, prefix, depth + 1, codes, lengths)
}

#[no_mangle]
pub unsafe extern "C" fn shannon_fano_compressor(input: *const i64, input_length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input_length > 18 || (input.is_null() && input_length != 0) || (!input.is_null() && input_length == 0) { return -1; }
    let mut text_length = 0usize;
    if !input.is_null() {
        let first = *input;
        if first < 0 || first > MAX_TEXT as i64 { return -1; }
        text_length = first as usize;
        if input_length != text_length + 1 { return -1; }
    }
    let mut text = [0u8; MAX_TEXT];
    let mut symbols = [0u8; MAX_SYMBOLS];
    let mut counts = [0usize; 128];
    let mut seen = [false; 128];
    let mut symbol_count = 0usize;
    for i in 0..text_length {
        let value = *input.add(i + 1);
        if !(0..=127).contains(&value) { return -1; }
        let s = value as usize;
        text[i] = s as u8;
        if !seen[s] { seen[s] = true; symbols[symbol_count] = s as u8; symbol_count += 1; }
        counts[s] += 1;
    }
    let mut freq = [0.0f64; 128];
    if text_length != 0 { for s in 0..128 { freq[s] = (1.0 * counts[s] as f64) / text_length as f64; } }
    let mut codes = [[0u8; MAX_CODE]; 128];
    let mut lengths = [0u8; 128];
    if symbol_count == 1 { codes[symbols[0] as usize][0] = b'1'; lengths[symbols[0] as usize] = 1; }
    else if symbol_count > 1 {
        let mut prefix = [0u8; MAX_CODE];
        if !make_codes(&symbols[..symbol_count], &freq, &mut prefix, 0, &mut codes, &mut lengths) { return -1; }
    }
    let mut staged = [0u8; MAX_OUTPUT];
    let mut n = 0usize;
    let compressed_length: usize = text[..text_length].iter().map(|&s| lengths[s as usize] as usize).sum();
    staged[n] = compressed_length as u8; n += 1;
    for &s in &text[..text_length] { let len = lengths[s as usize] as usize; staged[n..n+len].copy_from_slice(&codes[s as usize][..len]); n += len; }
    staged[n] = symbol_count as u8; n += 1;
    for s in 0..128 { let len = lengths[s] as usize; if len != 0 { staged[n] = s as u8; n += 1; staged[n] = len as u8; n += 1; staged[n..n+len].copy_from_slice(&codes[s][..len]); n += len; } }
    if output.is_null() || capacity < n { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, n);
    n as i64
}
