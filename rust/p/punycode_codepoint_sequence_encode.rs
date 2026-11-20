const MAX_POINTS: usize = 32;
const MAX_WORDS: usize = 34;
const MAX_OUTPUT: usize = 320;

fn adapt_bias(mut delta: i64, point_count: i64, first_time: bool) -> i64 {
    delta /= if first_time { 700 } else { 2 };
    delta += delta / point_count;
    let mut k = 0;
    while delta > ((36 - 1) * 26) / 2 {
        delta /= 35;
        k += 36;
    }
    k + (36 * delta) / (delta + 38)
}

fn digit_byte(digit: i64) -> u8 {
    if digit < 26 { b'a' + digit as u8 } else { b'0' + (digit - 26) as u8 }
}

fn is_scalar(value: i64) -> bool {
    (0..=0x10ffff).contains(&value) && !(0xd800..=0xdfff).contains(&value)
}

fn encode(points: &[i64], staged: &mut [u8; MAX_OUTPUT]) -> usize {
    let mut basic_count = 0;
    for &point in points {
        if point < 0x80 {
            staged[basic_count] = point as u8;
            basic_count += 1;
        }
    }
    let mut written = basic_count;
    if basic_count != 0 {
        staged[written] = b'-';
        written += 1;
    }
    let (mut n, mut delta, mut bias) = (128i64, 0i64, 72i64);
    let mut handled = basic_count;
    while handled < points.len() {
        let minimum = points.iter().copied().filter(|&point| point >= n).min().unwrap_or(0);
        delta += (minimum - n) * (handled as i64 + 1);
        n = minimum;
        for &point in points {
            if point < n { delta += 1; }
            if point == n {
                let mut q = delta;
                let mut k = 36i64;
                loop {
                    let threshold = if k <= bias { 1 } else if k >= bias + 26 { 26 } else { k - bias };
                    if q < threshold {
                        staged[written] = digit_byte(q);
                        written += 1;
                        break;
                    }
                    staged[written] = digit_byte(threshold + (q - threshold) % (36 - threshold));
                    written += 1;
                    q = (q - threshold) / (36 - threshold);
                    k += 36;
                }
                bias = adapt_bias(delta, handled as i64 + 1, handled == basic_count);
                delta = 0;
                handled += 1;
            }
        }
        delta += 1;
        n += 1;
    }
    written
}

#[no_mangle]
pub unsafe extern "C" fn punycode_codepoint_sequence_encode(
    input_pointer: *const i64,
    length: usize,
    output_pointer: *mut u8,
    capacity: usize,
) -> i64 {
    if input_pointer.is_null() || !(1..=MAX_WORDS).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_pointer, length) };
    let count_word = input[0];
    if !(0..=MAX_POINTS as i64).contains(&count_word) || length != count_word as usize + 1 { return -1; }
    let points = &input[1..];
    if points.iter().any(|&point| !is_scalar(point)) { return -1; }
    let mut staged = [0u8; MAX_OUTPUT];
    let written = encode(points, &mut staged);
    if written > MAX_OUTPUT { return -1; }
    if written != 0 && (output_pointer.is_null() || capacity < written) { return -2; }
    if written != 0 {
        unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output_pointer, written); }
    }
    written as i64
}
