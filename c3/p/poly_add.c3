module poly_add;

const MAX_TERMS = 16;
const MAX_INPUT_VALUES = 67;
const MAX_OUTPUT_TERMS = 32;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn bool validate_terms(long* input, usz start, usz count) {
    long previous_degree = 64;
    for (usz i = 0; i < count; i++) {
        long coefficient = input[start + 2 * i];
        long degree = input[start + 2 * i + 1];
        if (coefficient < -1000000 || coefficient > 1000000
            || degree < 0 || degree > 63 || degree >= previous_degree) return false;
        previous_degree = degree;
    }
    return true;
}

fn long poly_add(long* input, usz length, char* output, usz output_capacity)
    @export("poly_add") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long count_a_value = input[0];
    if (count_a_value < 1 || count_a_value > MAX_TERMS) return -1;
    usz count_a = (usz)count_a_value;
    usz count_b_index = 1 + 2 * count_a;
    if (length <= count_b_index) return -1;
    long count_b_value = input[count_b_index];
    if (count_b_value < 1 || count_b_value > MAX_TERMS) return -1;
    usz count_b = (usz)count_b_value;
    if (length != 2 + 2 * (count_a + count_b)) return -1;

    usz start_a = 1;
    usz start_b = count_b_index + 1;
    if (!validate_terms(input, start_a, count_a)
        || !validate_terms(input, start_b, count_b)) return -1;

    long[MAX_OUTPUT_TERMS] coefficients;
    long[MAX_OUTPUT_TERMS] degrees;
    usz i = 0, j = 0, terms = 0;
    while (i < count_a && j < count_b) {
        long coefficient_a = input[start_a + 2 * i];
        long degree_a = input[start_a + 2 * i + 1];
        long coefficient_b = input[start_b + 2 * j];
        long degree_b = input[start_b + 2 * j + 1];
        if (degree_a > degree_b) {
            coefficients[terms] = coefficient_a; degrees[terms++] = degree_a; i++;
        } else if (degree_a < degree_b) {
            coefficients[terms] = coefficient_b; degrees[terms++] = degree_b; j++;
        } else {
            coefficients[terms] = coefficient_a + coefficient_b; degrees[terms++] = degree_a;
            i++; j++;
        }
    }
    while (i < count_a) {
        coefficients[terms] = input[start_a + 2 * i];
        degrees[terms++] = input[start_a + 2 * i + 1]; i++;
    }
    while (j < count_b) {
        coefficients[terms] = input[start_b + 2 * j];
        degrees[terms++] = input[start_b + 2 * j + 1]; j++;
    }

    usz required = terms * 16;
    if (output == null || output_capacity < required) return -2;
    for (usz term = 0; term < terms; term++) {
        put_i64_le(output, term * 16, coefficients[term]);
        put_i64_le(output, term * 16 + 8, degrees[term]);
    }
    return (long)required;
}
