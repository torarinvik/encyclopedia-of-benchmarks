/// Enumerate amicable pairs below an exclusive upper limit using a divisor-sum sieve.
const MAX_LIMIT: usize = 8_000;

unsafe fn write_u32_le(output: *mut u8, position: &mut usize, value: i64) {
    let encoded = value as u32;
    for byte in 0..4 {
        output.add(*position).write((encoded >> (8 * byte)) as u8);
        *position += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn amicable_pairs_below(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let limit_value = *values;
    if !(1..=MAX_LIMIT as i64).contains(&limit_value) { return -1; }
    let limit = limit_value as usize;
    let mut divisor_sums = [0i64; MAX_LIMIT];
    for divisor in 1..limit {
        let mut multiple = divisor * 2;
        while multiple < limit {
            divisor_sums[multiple] += divisor as i64;
            multiple += divisor;
        }
    }

    let mut pair_count = 0usize;
    for smaller in 2..limit {
        let larger = divisor_sums[smaller];
        if larger > smaller as i64 && larger < limit as i64 &&
            divisor_sums[larger as usize] == smaller as i64 {
            pair_count += 1;
        }
    }
    let required = pair_count * 8;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }

    let mut position = 0usize;
    for smaller in 2..limit {
        let larger = divisor_sums[smaller];
        if larger > smaller as i64 && larger < limit as i64 &&
            divisor_sums[larger as usize] == smaller as i64 {
            write_u32_le(output, &mut position, smaller as i64);
            write_u32_le(output, &mut position, larger);
        }
    }
    pair_count as i64
}
