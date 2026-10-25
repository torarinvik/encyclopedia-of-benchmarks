/// Clean-room bounded pcompress2 compression pipeline.
const MAX_LENGTH: usize = 32;
const MAX_OUTPUT: usize = 8 + MAX_LENGTH * 16;
const SYMBOLS: usize = 257;

struct BitWriter { bytes: [u8; MAX_OUTPUT], length: usize, buffer: u8, bits_to_go: i32 }
impl BitWriter {
    fn new() -> Self { Self { bytes: [0; MAX_OUTPUT], length: 0, buffer: 0, bits_to_go: 8 } }
    fn output_bit(&mut self, bit: bool) {
        self.buffer >>= 1;
        if bit { self.buffer |= 0x80; }
        self.bits_to_go -= 1;
        if self.bits_to_go == 0 { self.bytes[self.length] = self.buffer; self.length += 1; self.bits_to_go = 8; }
    }
    fn bit_plus_follow(&mut self, bit: bool, follow: &mut i32) {
        self.output_bit(bit);
        while *follow > 0 { self.output_bit(!bit); *follow -= 1; }
    }
}

fn rotation_less(input: &[u8], left: usize, right: usize) -> bool {
    for offset in 0..input.len() {
        let a = input[(left + offset) % input.len()];
        let b = input[(right + offset) % input.len()];
        if a != b { return a < b; }
    }
    left < right
}

fn encode_symbol(symbol: usize, cum: &[i32; 258], low: &mut u32, high: &mut u32,
                 follow: &mut i32, writer: &mut BitWriter) {
    let span = u64::from(*high - *low) + 1;
    let old_low = *low;
    *high = old_low + (span * cum[symbol - 1] as u64 / cum[0] as u64) as u32 - 1;
    *low = old_low + (span * cum[symbol] as u64 / cum[0] as u64) as u32;
    loop {
        if *high < 32768 { writer.bit_plus_follow(false, follow); }
        else if *low >= 32768 { writer.bit_plus_follow(true, follow); *low -= 32768; *high -= 32768; }
        else if *low >= 16384 && *high < 49152 { *follow += 1; *low -= 16384; *high -= 16384; }
        else { break; }
        *low *= 2; *high = *high * 2 + 1;
    }
}

fn update_model(symbol: usize, char_to_index: &mut [usize; 256], index_to_char: &mut [u8; 258],
                freq: &mut [i32; 258], cum: &mut [i32; 258]) {
    if cum[0] == 16383 {
        let mut total = 0;
        for i in (0..=SYMBOLS).rev() { freq[i] = (freq[i] + 1) / 2; cum[i] = total; total += freq[i]; }
    }
    let mut i = symbol;
    while freq[i] == freq[i - 1] { i -= 1; }
    if i < symbol {
        let a = index_to_char[i]; let b = index_to_char[symbol];
        index_to_char[i] = b; index_to_char[symbol] = a;
        char_to_index[a as usize] = symbol; char_to_index[b as usize] = i;
    }
    freq[i] += 1;
    while i > 0 { i -= 1; cum[i] += 1; }
}

fn arithmetic_encode(data: &[u8]) -> BitWriter {
    let mut char_to_index = [0usize; 256];
    let mut index_to_char = [0u8; 258];
    let mut freq = [1i32; 258];
    let mut cum = [0i32; 258];
    for i in 0..256 { char_to_index[i] = i + 1; index_to_char[i + 1] = i as u8; }
    for i in 0..=SYMBOLS { cum[i] = SYMBOLS as i32 - i as i32; }
    freq[0] = 0;
    let mut writer = BitWriter::new(); let mut low = 0u32; let mut high = 65535u32; let mut follow = 0;
    for &byte in data {
        let symbol = char_to_index[byte as usize];
        encode_symbol(symbol, &cum, &mut low, &mut high, &mut follow, &mut writer);
        update_model(symbol, &mut char_to_index, &mut index_to_char, &mut freq, &mut cum);
    }
    encode_symbol(257, &cum, &mut low, &mut high, &mut follow, &mut writer);
    follow += 1;
    writer.bit_plus_follow(low >= 16384, &mut follow);
    writer.bytes[writer.length] = writer.buffer >> writer.bits_to_go;
    writer.length += 1;
    writer
}

fn compress_bounded(input: &[u8]) -> ([u8; MAX_OUTPUT], usize) {
    let n = input.len();
    let mut order = [0usize; MAX_LENGTH];
    let mut last = [0u8; MAX_LENGTH];
    let mut rle = [0u8; MAX_LENGTH * 2];
    let mut rle_length = 0;
    for i in 0..n { order[i] = i; }
    for i in 1..n {
        let key = order[i]; let mut j = i;
        while j > 0 && rotation_less(input, key, order[j - 1]) { order[j] = order[j - 1]; j -= 1; }
        order[j] = key;
    }
    let mut primary = 0;
    for row in 0..n { if order[row] == 0 { primary = row; } last[row] = input[(order[row] + n - 1) % n]; }
    let mut i = 0;
    while i < n {
        let mut count = 1; let value = last[i];
        while i + count < n && last[i + count] == value && count < 127 { count += 1; }
        if count == 1 {
            while i + count < n && last[i + count - 1] != last[i + count] &&
                  (i + count + 1 == n || last[i + count] != last[i + count + 1]) { count += 1; }
            rle[rle_length] = (count & 0x7f) as u8; rle_length += 1;
            for j in 0..count { rle[rle_length] = last[i + j]; rle_length += 1; }
            i += count;
        } else { rle[rle_length] = (count | 0x80) as u8; rle_length += 1; rle[rle_length] = value; rle_length += 1; i += count; }
    }
    let mut output = [0u8; MAX_OUTPUT];
    output[0] = n as u8; output[4] = primary as u8;
    let writer = arithmetic_encode(&rle[..rle_length]);
    let total = 8 + writer.length;
    output[8..total].copy_from_slice(&writer.bytes[..writer.length]);
    (output, total)
}

#[no_mangle]
pub unsafe extern "C" fn pcompress2(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 2 { return -1; }
    let declared = *values;
    if declared < 1 || declared > MAX_LENGTH as i64 { return -1; }
    let n = declared as usize;
    if length != n + 1 { return -1; }
    let mut input = [0u8; MAX_LENGTH];
    for i in 0..n { let value = *values.add(i + 1); if !(0..=255).contains(&value) { return -1; } input[i] = value as u8; }
    let (encoded, encoded_length) = compress_bounded(&input[..n]);
    if output.is_null() || output_capacity < encoded_length { return -2; }
    for i in 0..encoded_length { *output.add(i) = encoded[i]; }
    encoded_length as i64
}
