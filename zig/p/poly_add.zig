const MAX_TERMS: usize = 16;
const MAX_INPUT_VALUES: usize = 67;
const MAX_OUTPUT_TERMS: usize = 32;

fn validateTerms(input: [*c]const i64, start: usize, count: usize) bool {
    var previous_degree: i64 = 64;
    for (0..count) |i| {
        const coefficient = input[start + 2 * i];
        const degree = input[start + 2 * i + 1];
        if (coefficient < -1_000_000 or coefficient > 1_000_000
            or degree < 0 or degree > 63 or degree >= previous_degree) return false;
        previous_degree = degree;
    }
    return true;
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn poly_add(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const count_a_value = input[0];
    if (count_a_value < 1 or count_a_value > MAX_TERMS) return -1;
    const count_a: usize = @intCast(count_a_value);
    const count_b_index = 1 + 2 * count_a;
    if (length <= count_b_index) return -1;
    const count_b_value = input[count_b_index];
    if (count_b_value < 1 or count_b_value > MAX_TERMS) return -1;
    const count_b: usize = @intCast(count_b_value);
    if (length != 2 + 2 * (count_a + count_b)) return -1;

    const start_a: usize = 1;
    const start_b = count_b_index + 1;
    if (!validateTerms(input, start_a, count_a) or !validateTerms(input, start_b, count_b)) return -1;

    var coefficients: [MAX_OUTPUT_TERMS]i64 = @splat(0);
    var degrees: [MAX_OUTPUT_TERMS]i64 = @splat(0);
    var i: usize = 0;
    var j: usize = 0;
    var terms: usize = 0;
    while (i < count_a and j < count_b) {
        const coefficient_a = input[start_a + 2 * i];
        const degree_a = input[start_a + 2 * i + 1];
        const coefficient_b = input[start_b + 2 * j];
        const degree_b = input[start_b + 2 * j + 1];
        if (degree_a > degree_b) {
            coefficients[terms] = coefficient_a; degrees[terms] = degree_a; terms += 1; i += 1;
        } else if (degree_a < degree_b) {
            coefficients[terms] = coefficient_b; degrees[terms] = degree_b; terms += 1; j += 1;
        } else {
            coefficients[terms] = coefficient_a + coefficient_b; degrees[terms] = degree_a;
            terms += 1; i += 1; j += 1;
        }
    }
    while (i < count_a) {
        coefficients[terms] = input[start_a + 2 * i];
        degrees[terms] = input[start_a + 2 * i + 1];
        terms += 1; i += 1;
    }
    while (j < count_b) {
        coefficients[terms] = input[start_b + 2 * j];
        degrees[terms] = input[start_b + 2 * j + 1];
        terms += 1; j += 1;
    }

    const required = terms * 16;
    if (output == null or output_capacity < required) return -2;
    for (0..terms) |term| {
        putI64Le(output, term * 16, coefficients[term]);
        putI64Le(output, term * 16 + 8, degrees[term]);
    }
    return @intCast(required);
}
