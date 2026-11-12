module product_of_polynomial_sequence;

const long MODULUS = 998244353;
const usz MAX_FACTORS = 6;
const usz MAX_COEFFICIENTS = 25;
const usz MAX_INPUT = 38;

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long product_of_polynomial_sequence(long* input, usz length, uint8* output, usz capacity)
    @export("product_of_polynomial_sequence") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_FACTORS) return -1;
    usz count = (usz)input[0];
    long[MAX_FACTORS * MAX_COEFFICIENTS] polynomials = {0};
    usz[MAX_FACTORS] poly_lengths = {0};
    usz cursor = 1;
    usz degree_sum = 0;
    for (usz p = 0; p < count; p++) {
        if (cursor >= length || input[cursor] < 0 || input[cursor] > 4) return -1;
        usz degree = (usz)input[cursor++];
        if (cursor + degree + 1 > length) return -1;
        for (usz i = 0; i <= degree; i++) {
            long coefficient = input[cursor + i];
            if (coefficient < 0 || coefficient >= MODULUS) return -1;
            polynomials[p * MAX_COEFFICIENTS + i] = coefficient;
        }
        if (polynomials[p * MAX_COEFFICIENTS + degree] == 0) return -1;
        poly_lengths[p] = degree + 1;
        degree_sum += degree;
        cursor += degree + 1;
    }
    if (cursor != length) return -1;

    usz result_length = degree_sum + 1;
    usz bytes = 8 * result_length;
    if (output == null || capacity < bytes) return -2;
    if (count == 0) {
        store_le(output, 0, 1);
        return 8;
    }

    long[MAX_COEFFICIENTS] scratch = {0};
    usz active = count;
    while (active > 1) {
        usz next_count = 0;
        for (usz i = 0; i < active; i += 2) {
            usz destination = next_count * MAX_COEFFICIENTS;
            if (i + 1 == active) {
                usz source = i * MAX_COEFFICIENTS;
                for (usz j = 0; j < poly_lengths[i]; j++)
                    polynomials[destination + j] = polynomials[source + j];
                poly_lengths[next_count] = poly_lengths[i];
            } else {
                usz left_start = i * MAX_COEFFICIENTS;
                usz right_start = (i + 1) * MAX_COEFFICIENTS;
                usz left_length = poly_lengths[i];
                usz right_length = poly_lengths[i + 1];
                usz product_length = left_length + right_length - 1;
                for (usz j = 0; j < product_length; j++) scratch[j] = 0;
                for (usz a = 0; a < left_length; a++) {
                    for (usz b = 0; b < right_length; b++) {
                        usz slot = a + b;
                        scratch[slot] = (scratch[slot] +
                            polynomials[left_start + a] * polynomials[right_start + b]) % MODULUS;
                    }
                }
                for (usz j = 0; j < product_length; j++)
                    polynomials[destination + j] = scratch[j];
                poly_lengths[next_count] = product_length;
            }
            next_count++;
        }
        active = next_count;
    }
    for (usz i = 0; i < result_length; i++) store_le(output, 8 * i, polynomials[i]);
    return (long)bytes;
}
