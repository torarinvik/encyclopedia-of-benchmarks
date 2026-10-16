/// Return source-ordered unit-fraction denominators as little-endian i32s.
#[no_mangle]
pub unsafe extern "C" fn egyptian_fraction(input: *const i64, length: usize,
                                             output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let mut numerator = *input;
    let mut denominator = *input.add(1);
    if numerator < 0 || denominator < 1 || denominator > 10 || numerator > denominator { return -1; }

    let mut terms = [0u32; 10];
    let mut count = 0usize;
    while numerator != 0 {
        let mut unit_denominator = denominator / numerator;
        if denominator % numerator != 0 { unit_denominator += 1; }
        terms[count] = unit_denominator as u32;
        count += 1;
        numerator = numerator * unit_denominator - denominator;
        denominator = denominator * unit_denominator;
    }
    let required = count * 4;
    if output_capacity < required || (required > 0 && output.is_null()) { return -2; }
    for index in 0..count {
        for byte in 0..4 { *output.add(index * 4 + byte) = (terms[index] >> (8 * byte)) as u8; }
    }
    required as i64
}
