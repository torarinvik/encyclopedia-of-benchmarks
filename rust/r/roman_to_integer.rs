fn decode_roman_digit(symbols: &[i64], position: usize, one: i64, five: i64, ten: i64) -> i64 {
    if position >= symbols.len() { return 0; }
    if symbols[position] == one {
        if position + 1 < symbols.len() && symbols[position + 1] == ten { return 146; }
        if position + 1 < symbols.len() && symbols[position + 1] == five { return 66; }
        let mut count = 0usize;
        while position + count < symbols.len() && symbols[position + count] == one && count < 3 { count += 1; }
        if position + count < symbols.len() && symbols[position + count] == one { return -1; }
        return (count * 16 + count) as i64;
    }
    if symbols[position] == five {
        let mut count = 0usize;
        while position + 1 + count < symbols.len() && symbols[position + 1 + count] == one && count < 3 { count += 1; }
        if position + 1 + count < symbols.len() && symbols[position + 1 + count] == one { return -1; }
        return ((5 + count) * 16 + 1 + count) as i64;
    }
    0
}

/// Decode canonical uppercase Roman numerals in the range 1 through 3,999.
#[no_mangle]
pub extern "C" fn roman_to_integer(symbols: *const i64, length: usize) -> i64 {
    if length == 0 || length > 15 { return -1; }
    let symbols = unsafe { std::slice::from_raw_parts(symbols, length) };
    if symbols.iter().any(|&symbol| !matches!(symbol, 73 | 86 | 88 | 76 | 67 | 68 | 77)) { return -1; }
    let mut position = 0usize;
    let mut thousands = 0usize;
    while position < length && symbols[position] == 77 && thousands < 3 {
        position += 1;
        thousands += 1;
    }
    if position < length && symbols[position] == 77 { return -1; }
    let hundreds = decode_roman_digit(symbols, position, 67, 68, 77);
    if hundreds < 0 { return -1; }
    position += (hundreds & 15) as usize;
    let tens = decode_roman_digit(symbols, position, 88, 76, 67);
    if tens < 0 { return -1; }
    position += (tens & 15) as usize;
    let ones = decode_roman_digit(symbols, position, 73, 86, 88);
    if ones < 0 { return -1; }
    position += (ones & 15) as usize;
    if position != length { return -1; }
    let value = thousands as i64 * 1000 + (hundreds >> 4) * 100 + (tens >> 4) * 10 + (ones >> 4);
    if !(1..=3999).contains(&value) { return -1; }
    value
}
