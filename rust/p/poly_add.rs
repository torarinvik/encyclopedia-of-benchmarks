const MAX_TERMS: usize = 16;
const MAX_INPUT_VALUES: usize = 67;
const MAX_OUTPUT_TERMS: usize = 32;

fn validate_terms(input: *const i64, start: usize, count: usize) -> bool {
    let mut previous_degree = 64i64;
    for i in 0..count {
        let coefficient = unsafe { *input.add(start + 2 * i) };
        let degree = unsafe { *input.add(start + 2 * i + 1) };
        if !(-1_000_000..=1_000_000).contains(&coefficient)
            || !(0..=63).contains(&degree) || degree >= previous_degree { return false; }
        previous_degree = degree;
    }
    true
}

fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for byte in 0..8 { unsafe { *output.add(offset + byte) = bytes[byte]; } }
}

#[no_mangle]
pub unsafe extern "C" fn poly_add(input: *const i64, length: usize,
                                    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let count_a_value = *input;
    if !(1..=MAX_TERMS as i64).contains(&count_a_value) { return -1; }
    let count_a = count_a_value as usize;
    let count_b_index = 1 + 2 * count_a;
    if length <= count_b_index { return -1; }
    let count_b_value = *input.add(count_b_index);
    if !(1..=MAX_TERMS as i64).contains(&count_b_value) { return -1; }
    let count_b = count_b_value as usize;
    if length != 2 + 2 * (count_a + count_b) { return -1; }

    let start_a = 1;
    let start_b = count_b_index + 1;
    if !validate_terms(input, start_a, count_a) || !validate_terms(input, start_b, count_b) { return -1; }

    let mut coefficients = [0i64; MAX_OUTPUT_TERMS];
    let mut degrees = [0i64; MAX_OUTPUT_TERMS];
    let (mut i, mut j, mut terms) = (0usize, 0usize, 0usize);
    while i < count_a && j < count_b {
        let coefficient_a = *input.add(start_a + 2 * i);
        let degree_a = *input.add(start_a + 2 * i + 1);
        let coefficient_b = *input.add(start_b + 2 * j);
        let degree_b = *input.add(start_b + 2 * j + 1);
        if degree_a > degree_b {
            coefficients[terms] = coefficient_a; degrees[terms] = degree_a; terms += 1; i += 1;
        } else if degree_a < degree_b {
            coefficients[terms] = coefficient_b; degrees[terms] = degree_b; terms += 1; j += 1;
        } else {
            coefficients[terms] = coefficient_a + coefficient_b; degrees[terms] = degree_a;
            terms += 1; i += 1; j += 1;
        }
    }
    while i < count_a {
        coefficients[terms] = *input.add(start_a + 2 * i);
        degrees[terms] = *input.add(start_a + 2 * i + 1);
        terms += 1; i += 1;
    }
    while j < count_b {
        coefficients[terms] = *input.add(start_b + 2 * j);
        degrees[terms] = *input.add(start_b + 2 * j + 1);
        terms += 1; j += 1;
    }

    let required = terms * 16;
    if output.is_null() || output_capacity < required { return -2; }
    for term in 0..terms {
        put_i64_le(output, term * 16, coefficients[term]);
        put_i64_le(output, term * 16 + 8, degrees[term]);
    }
    required as i64
}
