module matrix_det_arbitrary_mod;

const usz MAX_N = 8;
const usz MAX_INPUT_VALUES = 2 + MAX_N * MAX_N + 1;
const long MAX_MODULUS = 1000000000;

fn long normalize(long value, long modulus) {
    value %= modulus;
    if (value < 0) value += modulus;
    return value;
}

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long matrix_det_arbitrary_mod(long* input, usz length, char* output, usz capacity)
    @export("matrix_det_arbitrary_mod") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0], modulus = input[1];
    if (n_value < 0 || n_value > (long)MAX_N || modulus < 2 || modulus > MAX_MODULUS)
        return -1;
    usz n = (usz)n_value;
    if (length != 2 + n * n) return -1;

    long[MAX_N * MAX_N] matrix;
    for (usz index = 0; index < MAX_N * MAX_N; index += 1) matrix[index] = 0;
    for (usz row = 0; row < n; row += 1) {
        for (usz column = 0; column < n; column += 1) {
            long value = input[2 + row * n + column];
            if (value < 0 || value >= modulus) return -1;
            matrix[row * n + column] = value;
        }
    }

    long determinant = 1;
    bool sign = false;
    for (usz column = 0; column < n; column += 1) {
        usz pivot = column;
        while (pivot < n && matrix[pivot * n + column] == 0) pivot += 1;
        if (pivot == n) {
            determinant = 0;
            break;
        }
        if (pivot != column) {
            for (usz k = 0; k < n; k += 1) {
                long temporary = matrix[column * n + k];
                matrix[column * n + k] = matrix[pivot * n + k];
                matrix[pivot * n + k] = temporary;
            }
            sign = !sign;
        }
        for (usz row = column + 1; row < n; row += 1) {
            long left = matrix[column * n + column];
            long right = matrix[row * n + column];
            if (right == 0) continue;
            long a0 = 1, a1 = 0, b0 = 0, b1 = 1;
            while (left != 0 && right != 0) {
                if (left < right) {
                    long quotient = right / left;
                    right -= quotient * left;
                    b0 = normalize(b0 - a0 * quotient, modulus);
                    b1 = normalize(b1 - a1 * quotient, modulus);
                } else {
                    long quotient = left / right;
                    left -= quotient * right;
                    a0 = normalize(a0 - b0 * quotient, modulus);
                    a1 = normalize(a1 - b1 * quotient, modulus);
                }
            }
            for (usz k = column; k < n; k += 1) {
                long old_top = matrix[column * n + k];
                long old_bottom = matrix[row * n + k];
                matrix[column * n + k] = normalize(old_top * a0 + old_bottom * a1, modulus);
                matrix[row * n + k] = normalize(old_top * b0 + old_bottom * b1, modulus);
            }
            if (left == 0) {
                for (usz k = 0; k < n; k += 1) {
                    long temporary = matrix[column * n + k];
                    matrix[column * n + k] = matrix[row * n + k];
                    matrix[row * n + k] = temporary;
                }
                sign = !sign;
            }
        }
        determinant = determinant * matrix[column * n + column] % modulus;
        if (determinant == 0) break;
    }
    if (sign && determinant != 0) determinant = modulus - determinant;
    if (output == null || capacity < 8) return -2;
    store_i64_le(output, determinant);
    return 8;
}
