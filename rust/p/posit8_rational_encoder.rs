const MAX_COUNT: usize = 32;
const MAX_WORDS: usize = 66;

fn positive_units(code: u8) -> u64 {
    let mut cursor: i32 = 6;
    let regime_bit = (code >> 6) & 1;
    let mut run: i32 = 0;
    while cursor >= 0 && ((code >> cursor as u32) & 1) == regime_bit {
        run += 1;
        cursor -= 1;
    }
    let regime = if regime_bit != 0 { run - 1 } else { -run };
    if cursor >= 0 { cursor -= 1; }
    let mut exponent: i32 = 0;
    for _ in 0..2 {
        exponent <<= 1;
        if cursor >= 0 {
            exponent |= ((code >> cursor as u32) & 1) as i32;
            cursor -= 1;
        }
    }
    let width = (cursor + 1) as u32;
    let fraction = if width == 0 { 0 } else { (code & ((1u16 << width) - 1) as u8) as u64 };
    let significand = (1u64 << width) + fraction;
    let shift = 4 * regime + exponent + 24 - width as i32;
    significand << shift as u32
}

fn compare_ratio_to_unit(scaled: u64, denominator: u64, unit: u64) -> i32 {
    let quotient = scaled / denominator;
    let remainder = scaled % denominator;
    if quotient < unit { -1 }
    else if quotient > unit { 1 }
    else if remainder == 0 { 0 }
    else { 1 }
}

fn encode_one(numerator: i64, denominator: i64) -> u8 {
    if numerator == 0 { return 0; }
    let negative = numerator < 0;
    let magnitude = numerator.unsigned_abs();
    let scaled = magnitude << 24;
    let chosen: u8;
    if compare_ratio_to_unit(scaled, denominator as u64, 1) <= 0 {
        chosen = 1;
    } else if compare_ratio_to_unit(scaled, denominator as u64, positive_units(127)) >= 0 {
        chosen = 127;
    } else {
        let (mut low, mut high) = (1i32, 127i32);
        while low < high {
            let middle = low + (high - low) / 2;
            if compare_ratio_to_unit(scaled, denominator as u64, positive_units(middle as u8)) > 0 { low = middle + 1; }
            else { high = middle; }
        }
        let upper = low as u8;
        let lower = upper - 1;
        let midpoint = positive_units(lower) + positive_units(upper);
        let midpoint_comparison = compare_ratio_to_unit(scaled << 1, denominator as u64, midpoint);
        chosen = if midpoint_comparison < 0 { lower }
            else if midpoint_comparison > 0 { upper }
            else if lower & 1 == 0 { lower } else { upper };
    }
    if negative { chosen.wrapping_neg() } else { chosen }
}

#[no_mangle]
pub unsafe extern "C" fn posit8_rational_encoder(input_ptr: *const i64, length: usize,
                                                    output_ptr: *mut u8, capacity: usize) -> i64 {
    if input_ptr.is_null() || !(1..=MAX_WORDS).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_ptr, length) };
    let raw_count = input[0];
    if raw_count < 0 || raw_count > MAX_COUNT as i64 || length != 1 + raw_count as usize * 2 { return -1; }
    let count = raw_count as usize;
    for index in 0..count {
        let numerator = input[1 + 2 * index];
        let denominator = input[2 + 2 * index];
        if !(-(1i64 << 31)..=(1i64 << 31)).contains(&numerator) || !(1i64..=(1i64 << 31)).contains(&denominator) { return -1; }
    }
    if output_ptr.is_null() || capacity < count { return -2; }
    let mut staged = [0u8; MAX_COUNT];
    for index in 0..count { staged[index] = encode_one(input[1 + 2 * index], input[2 + 2 * index]); }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output_ptr, count); }
    count as i64
}
