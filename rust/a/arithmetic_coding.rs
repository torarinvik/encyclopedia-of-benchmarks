/// Return the exact scaled lower bound produced by arithmetic coding.
#[no_mangle]
pub extern "C" fn arithmetic_coding(input: *const i64, length: usize) -> i64 {
    if length < 2 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let count = input[0];
    if !(1..=12).contains(&count) || length != count as usize + 1 { return -1; }

    let mut frequency = [0i64; 256];
    let mut cumulative = [0i64; 257];
    for &symbol in &input[1..] {
        if !(0..=255).contains(&symbol) { return -1; }
        frequency[symbol as usize] += 1;
    }
    for symbol in 0..256 {
        cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol];
    }

    let mut low = 0i64;
    let mut high = 1i64;
    for &symbol in &input[1..] {
        let symbol = symbol as usize;
        let range = high - low;
        let base = low * count;
        high = base + range * cumulative[symbol + 1];
        low = base + range * cumulative[symbol];
    }
    low
}
