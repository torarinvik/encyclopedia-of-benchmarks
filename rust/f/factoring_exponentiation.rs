const FACTOR_LOG_32: [u32; 32] = [
    0x00000000, 0x00000000, 0xd3cfd984, 0x9ee62e18,
    0xe83d9070, 0xb59e81e0, 0xa17407c0, 0xce601f80,
    0xf4807f00, 0xe701fe00, 0xbe07fc00, 0xfc1ff800,
    0xf87ff000, 0xf1ffe000, 0xe7ffc000, 0xdfff8000,
    0xffff0000, 0xfffe0000, 0xfffc0000, 0xfff80000,
    0xfff00000, 0xffe00000, 0xffc00000, 0xff800000,
    0xff000000, 0xfe000000, 0xfc000000, 0xf8000000,
    0xf0000000, 0xe0000000, 0xc0000000, 0x80000000,
];

fn factoring_mask(d: u32) -> u64 {
    if d == 32 { u32::MAX as u64 } else { (1u64 << d) - 1 }
}

fn factoring_log(mut remainder: u64, mut value: u64, d: u32, modulus: u64, mask: u64) -> u64 {
    for bit in 2..d {
        if (value & (1u64 << bit)) != 0 {
            value = (value + (value << bit)) & mask;
            remainder = (remainder + modulus - (FACTOR_LOG_32[bit as usize] as u64 & mask)) & mask;
        }
    }
    remainder
}

fn factoring_exp(mut remainder: u64, mut exponent: u64, d: u32, modulus: u64, mask: u64) -> u64 {
    for bit in 2..d {
        if (exponent & (1u64 << bit)) != 0 {
            remainder = (remainder + (remainder << bit)) & mask;
            exponent = (exponent + modulus - (FACTOR_LOG_32[bit as usize] as u64 & mask)) & mask;
        }
    }
    remainder
}

#[no_mangle]
pub extern "C" fn factoring_exponentiation(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (remainder_input, base_input, exponent_input, d_input) =
        (values[0], values[1], values[2], values[3]);
    if !(3..=32).contains(&d_input) || remainder_input < 0 || base_input < 1 ||
        !(0..=4_294_967_295).contains(&exponent_input) { return -1; }
    let d = d_input as u32;
    let mask = factoring_mask(d);
    let modulus = mask + 1;
    if remainder_input as u64 >= modulus || base_input as u64 >= modulus || (base_input & 1) == 0 {
        return -1;
    }
    let mut remainder = remainder_input as u64;
    let mut base = base_input as u64;
    let exponent = exponent_input as u64;
    if (base & 2) != 0 {
        base = (modulus - base) & mask;
        if (exponent & 1) != 0 { remainder = (modulus - remainder) & mask; }
    }
    let log_value = factoring_log(0, base, d, modulus, mask);
    let scaled_log = (log_value * exponent) & mask;
    factoring_exp(remainder, scaled_log, d, modulus, mask) as i64
}
