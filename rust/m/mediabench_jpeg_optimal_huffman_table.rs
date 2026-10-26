const MAX_SYMBOLS: usize = 20;
const MAX_CLEN: usize = 32;

// Clean-room IJG JPEG 6a table-generation profile; see package LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn mediabench_jpeg_optimal_huffman_table(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > 41 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_SYMBOLS as i64 { return -1; }
    let count = values[0] as usize;
    if length != 1 + 2 * count { return -1; }
    for i in 0..count {
        let symbol = values[1 + 2 * i]; let frequency = values[2 + 2 * i];
        if !(0..=255).contains(&symbol) || !(1..=1_000_000).contains(&frequency) { return -1; }
        for j in 0..i { if values[1 + 2 * j] == symbol { return -1; } }
    }
    let out_size = 17 + count;
    if output.is_null() || capacity < out_size { return -2; }
    let mut freq = [0_i64; 257];
    let mut code_size = [0_i32; 257];
    let mut others = [-1_i32; 257];
    let mut bits = [0_i32; MAX_CLEN + 1];
    for i in 0..count { freq[values[1 + 2 * i] as usize] = values[2 + 2 * i]; }
    freq[256] = 1;
    loop {
        let (mut c1, mut c2) = (-1_i32, -1_i32);
        let mut value = 1_000_000_000_i64;
        for i in 0..=256 { if freq[i] != 0 && freq[i] <= value { value = freq[i]; c1 = i as i32; } }
        value = 1_000_000_000;
        for i in 0..=256 { if freq[i] != 0 && freq[i] <= value && i as i32 != c1 { value = freq[i]; c2 = i as i32; } }
        if c2 < 0 { break; }
        let (a, b) = (c1 as usize, c2 as usize);
        freq[a] += freq[b]; freq[b] = 0;
        code_size[a] += 1; while others[c1 as usize] >= 0 { c1 = others[c1 as usize]; code_size[c1 as usize] += 1; }
        others[c1 as usize] = c2;
        code_size[b] += 1; while others[c2 as usize] >= 0 { c2 = others[c2 as usize]; code_size[c2 as usize] += 1; }
    }
    for i in 0..=256 { if code_size[i] != 0 { if code_size[i] as usize > MAX_CLEN { return -1; } bits[code_size[i] as usize] += 1; } }
    for i in (17..=MAX_CLEN).rev() { while bits[i] > 0 {
        let mut j = i as i32 - 2; while j >= 0 && bits[j as usize] == 0 { j -= 1; }
        if j < 0 || bits[i] < 2 { return -1; }
        bits[i] -= 2; bits[i - 1] += 1; bits[j as usize + 1] += 2; bits[j as usize] -= 1;
    } }
    let mut longest = 16; while longest > 0 && bits[longest] == 0 { longest -= 1; }
    if longest == 0 { return -1; }
    bits[longest] -= 1;
    let symbol_count: usize = (1..=MAX_CLEN).map(|size| (0..256).filter(|&symbol| code_size[symbol] as usize == size).count()).sum();
    if symbol_count != count { return -1; }
    let out = std::slice::from_raw_parts_mut(output, out_size);
    out[0] = count as u8;
    for i in 1..=16 { out[i] = bits[i] as u8; }
    let mut used = 17;
    for size in 1..=MAX_CLEN { for symbol in 0..=255 { if code_size[symbol] as usize == size { out[used] = symbol as u8; used += 1; } } }
    out_size as i64
}
