/// Seeded portable port of the pinned logistic-map/Xorshift machine.
fn fraction_one(value: f64) -> f64 { value - value.floor() }
fn round_ten(value: f64) -> f64 {
    let bits = value.to_bits();
    let exponent = (bits >> 52) & 0x7ff;
    if exponent == 0 { return 0.0; }
    let mantissa = (1u64 << 52) | (bits & ((1u64 << 52) - 1));
    let low_product = (mantissa & 0xffff_ffff) * 9_765_625;
    let high_product = (mantissa >> 32) * 9_765_625;
    let shifted_high = high_product << 32;
    let low = shifted_high.wrapping_add(low_product);
    let carry = u64::from(low < shifted_high);
    let high = (high_product >> 32) + carry;
    let shift = 1065 - exponent as i32;
    if shift > 77 { return 0.0; }
    let (mut rounded, relation): (u64, i32) = if shift < 64 {
        let rounded = (high << (64 - shift)) | (low >> shift);
        let remainder = low & ((1u64 << shift) - 1);
        let half = 1u64 << (shift - 1);
        (rounded, if remainder > half { 1 } else if remainder < half { -1 } else { 0 })
    } else if shift == 64 {
        let half = 1u64 << 63;
        (high, if low > half { 1 } else if low < half { -1 } else { 0 })
    } else {
        let upper_bits = (shift - 64) as u32;
        let rounded = high >> upper_bits;
        let remainder_high = high & ((1u64 << upper_bits) - 1);
        let half_high = 1u64 << (upper_bits - 1);
        (rounded, if remainder_high > half_high || (remainder_high == half_high && low != 0) { 1 }
            else if remainder_high < half_high { -1 } else { 0 })
    };
    if relation > 0 || (relation == 0 && rounded & 1 != 0) { rounded += 1; }
    rounded as f64 / 10_000_000_000.0
}
fn pull(machine_time: &mut u64, buffer: &mut [f64; 5], params: &mut [f64; 5]) -> u32 {
    let key = (*machine_time % 5) as usize;
    for _ in 0..3 {
        let rate = params[key];
        let value = buffer[key];
        buffer[key] = round_ten(rate * value * (1.0 - value));
        params[key] = fraction_one(*machine_time as f64 * 0.01 + rate * 1.01) + 3.0;
    }
    let mut x = (buffer[(key + 2) % 5] * 10_000_000_000.0) as u64;
    let mut y = (buffer[(key + 3) % 5] * 10_000_000_000.0) as u64;
    *machine_time += 1;
    x ^= y >> 13; y ^= x << 17; x ^= y >> 5;
    (x & u32::MAX as u64) as u32
}
#[no_mangle]
pub unsafe extern "C" fn chaos_machine(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || !(2..=66).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if !(0..=64).contains(&values[0]) || length != values[0] as usize + 2 { return -1; }
    let seed_count = values[0] as usize;
    let pull_input = values[length - 1];
    if !(0..=64).contains(&pull_input) || values[1..1 + seed_count].iter().any(|&seed| !(0..=1_000_000).contains(&seed)) { return -1; }
    let required = 4 * pull_input as usize;
    if required > output_capacity || (required != 0 && output.is_null()) { return -2; }
    let mut buffer = [0.33, 0.44, 0.55, 0.44, 0.33];
    let mut params = [0.0; 5];
    let mut machine_time = 0u64;
    for &seed_input in &values[1..1 + seed_count] {
        let seed = seed_input as f64;
        for key in 0..5 {
            if buffer[key] == 0.0 { return -1; }
            let evolution = seed / buffer[key];
            let value = fraction_one(buffer[(key + 1) % 5] + evolution);
            let rate = fraction_one(params[key] + evolution) + 3.0;
            buffer[key] = round_ten(rate * value * (1.0 - value));
            params[key] = rate;
        }
        machine_time += 1;
    }
    let out = std::slice::from_raw_parts_mut(output, required);
    for index in 0..pull_input as usize {
        let result = pull(&mut machine_time, &mut buffer, &mut params);
        for byte in 0..4 { out[4 * index + byte] = (result >> (8 * byte)) as u8; }
    }
    required as i64
}
