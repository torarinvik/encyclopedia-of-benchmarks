module berkowitz_characteristic_polynomial;

const usz MAX_N = 7;
const usz MAX_INPUT_WORDS = 52;

fn long residue(long value, long modulus) {
    long result = value % modulus;
    return result < 0 ? result + modulus : result;
}

fn long negative_residue(long value, long modulus) {
    return value == 0 ? 0 : modulus - value;
}

fn void store_i64_le(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[word * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long berkowitz_characteristic_polynomial(long* input, usz length,
        char* output, usz output_capacity)
        @export("berkowitz_characteristic_polynomial") {
    if (input == null || length < 3 || length > MAX_INPUT_WORDS) return -1;
    long n64 = input[0];
    long modulus = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || modulus < 2 || modulus > 1000000000) return -1;
    usz n = (usz)n64;
    if (length != 2 + n * n) return -1;

    long[MAX_N * MAX_N] matrix = {0};
    for (usz i = 0; i < n * n; i++) {
        long entry = input[i + 2];
        if (entry < -1000000 || entry > 1000000) return -1;
        matrix[i] = residue(entry, modulus);
    }
    usz output_bytes = (n + 1) * 8;
    if (output == null || output_capacity < output_bytes) return -2;

    long[MAX_N + 1] coefficients = {0};
    long[MAX_N + 1] current = {0};
    long[MAX_N + 1] toeplitz = {0};
    long[MAX_N] vector = {0};
    long[MAX_N] next_vector = {0};
    coefficients[0] = 1;
    for (usz size = 1; size <= n; size++) {
        usz start = n - size;
        usz block = size - 1;
        for (usz i = 0; i <= size; i++) toeplitz[i] = 0;
        toeplitz[0] = 1;
        toeplitz[1] = negative_residue(matrix[start * n + start], modulus);
        for (usz row = 0; row < block; row++)
            vector[row] = matrix[(start + 1 + row) * n + start];

        for (usz power = 0; power < block; power++) {
            long dot = 0;
            for (usz col = 0; col < block; col++)
                dot = (dot + matrix[start * n + start + 1 + col] * vector[col]) % modulus;
            toeplitz[power + 2] = negative_residue(dot, modulus);
            for (usz row = 0; row < block; row++) {
                long value = 0;
                for (usz col = 0; col < block; col++)
                    value = (value + matrix[(start + 1 + row) * n + start + 1 + col]
                                      * vector[col]) % modulus;
                next_vector[row] = value;
            }
            for (usz row = 0; row < block; row++) vector[row] = next_vector[row];
        }

        for (usz i = 0; i <= size; i++) {
            long value = 0;
            usz last_child = i < size - 1 ? i : size - 1;
            for (usz j = 0; j <= last_child; j++)
                value = (value + toeplitz[i - j] * coefficients[j]) % modulus;
            current[i] = value;
        }
        for (usz i = 0; i <= size; i++) coefficients[i] = current[i];
    }
    for (usz i = 0; i <= n; i++) store_i64_le(output, i, coefficients[i]);
    return (long)output_bytes;
}
