module characteristic_polynomial;

const long MODULUS = 998244353;
const usz MAX_N = 8;
const usz MAX_INPUT_VALUES = 1 + MAX_N * MAX_N + 1;

fn long normalize(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long multiply(long left, long right) {
    return (left * right) % MODULUS;
}

fn long power(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long characteristic_polynomial(long* input, usz length, char* output, usz capacity)
    @export("characteristic_polynomial") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + n * n) return -1;

    long[MAX_N * MAX_N] matrix = zeroed;
    for (usz row = 0; row < n; row += 1) {
        for (usz column = 0; column < n; column += 1) {
            long value = input[1 + row * n + column];
            if (value < 0 || value >= MODULUS) return -1;
            matrix[row * MAX_N + column] = value;
        }
    }

    for (usz column = 0; column + 2 < n; column += 1) {
        usz pivot = column + 1;
        while (pivot < n && matrix[pivot * MAX_N + column] == 0) pivot += 1;
        if (pivot == n) continue;
        if (pivot != column + 1) {
            for (usz k = 0; k < n; k += 1) {
                long value = matrix[(column + 1) * MAX_N + k];
                matrix[(column + 1) * MAX_N + k] = matrix[pivot * MAX_N + k];
                matrix[pivot * MAX_N + k] = value;
            }
            for (usz k = 0; k < n; k += 1) {
                long value = matrix[k * MAX_N + column + 1];
                matrix[k * MAX_N + column + 1] = matrix[k * MAX_N + pivot];
                matrix[k * MAX_N + pivot] = value;
            }
        }
        long inverse = power(matrix[(column + 1) * MAX_N + column], MODULUS - 2);
        for (usz row = column + 2; row < n; row += 1) {
            if (matrix[row * MAX_N + column] == 0) continue;
            long factor = multiply(matrix[row * MAX_N + column], inverse);
            for (usz k = 0; k < n; k += 1)
                matrix[row * MAX_N + k] = normalize(
                    matrix[row * MAX_N + k] - multiply(factor, matrix[(column + 1) * MAX_N + k]));
            for (usz k = 0; k < n; k += 1)
                matrix[k * MAX_N + column + 1] = normalize(
                    matrix[k * MAX_N + column + 1] + multiply(factor, matrix[k * MAX_N + row]));
        }
    }

    long[(MAX_N + 1) * (MAX_N + 1)] coefficients = zeroed;
    coefficients[0] = 1;
    for (usz size = 1; size <= n; size += 1) {
        for (usz degree = 0; degree <= size; degree += 1) {
            long value = 0;
            if (degree > 0) value = coefficients[(size - 1) * (MAX_N + 1) + degree - 1];
            if (degree < size)
                value -= multiply(matrix[(size - 1) * MAX_N + size - 1],
                    coefficients[(size - 1) * (MAX_N + 1) + degree]);
            coefficients[size * (MAX_N + 1) + degree] = normalize(value);
        }
        long subdiagonal_product = 1;
        for (isz start = (isz)size - 2; start >= 0; start -= 1) {
            subdiagonal_product = multiply(subdiagonal_product,
                matrix[((usz)start + 1) * MAX_N + (usz)start]);
            long term = multiply(subdiagonal_product,
                matrix[(usz)start * MAX_N + size - 1]);
            for (usz degree = 0; degree <= (usz)start; degree += 1)
                coefficients[size * (MAX_N + 1) + degree] = normalize(
                    coefficients[size * (MAX_N + 1) + degree] -
                    multiply(term, coefficients[(usz)start * (MAX_N + 1) + degree]));
        }
    }

    usz output_bytes = 8 * (n + 1);
    if (output == null || capacity < output_bytes) return -2;
    for (usz degree = 0; degree <= n; degree += 1)
        store_i64_le(output + 8 * degree, coefficients[n * (MAX_N + 1) + degree]);
    return (long)output_bytes;
}
