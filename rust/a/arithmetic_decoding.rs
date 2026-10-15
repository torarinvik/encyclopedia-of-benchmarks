/// Decode an exact arithmetic-coded lower-bound numerator.
#[no_mangle]
pub unsafe extern "C" fn arithmetic_decoding(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let count = input[0];
    let alphabet_size = input[1];
    if !(1..=12).contains(&count) || !(1..=count).contains(&alphabet_size)
        || length != (3 + 2 * alphabet_size) as usize { return -1; }

    let mut denominator = 1i64;
    for _ in 0..count { denominator *= count; }
    let code = input[2];
    if code < 0 || code >= denominator { return -1; }

    let mut symbols = [0i64; 12];
    let mut cumulative = [0i64; 13];
    let mut total = 0i64;
    for index in 0..alphabet_size as usize {
        let symbol = input[3 + 2 * index];
        let frequency = input[4 + 2 * index];
        if !(0..=255).contains(&symbol) || frequency < 1 || frequency > count
            || (index > 0 && symbol <= symbols[index - 1]) { return -1; }
        symbols[index] = symbol;
        total += frequency;
        cumulative[index + 1] = total;
    }
    if total != count { return -1; }
    if capacity < count as usize || output.is_null() { return -2; }

    let mut low = 0i64;
    let mut high = 1i64;
    let mut scale = denominator / count;
    for step in 0..count as usize {
        let range = high - low;
        let base = low * count;
        let mut found = false;
        for index in 0..alphabet_size as usize {
            let symbol_low = base + range * cumulative[index];
            let symbol_high = base + range * cumulative[index + 1];
            if code >= symbol_low * scale && code < symbol_high * scale {
                *output.add(step) = symbols[index] as u8;
                low = symbol_low;
                high = symbol_high;
                found = true;
                break;
            }
        }
        if !found { return -1; }
        if step + 1 < count as usize { scale /= count; }
    }
    count
}
