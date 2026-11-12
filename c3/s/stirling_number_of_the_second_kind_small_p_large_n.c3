module stirling_number_of_the_second_kind_small_p_large_n;

const long MAX_N = 1000000000000000000;
const usz MAX_T = 8;
const usz MAX_K = 8;
const usz WIDTH = 9;

fn bool is_prime(long value) {
    if (value < 2) return false;
    long divisor = 2;
    while (divisor <= value / divisor) {
        if (value % divisor == 0) return false;
        divisor += 1;
    }
    return true;
}

fn long stirling_value(long n, usz k, long modulus) {
    long[WIDTH * WIDTH] matrix = zeroed;
    long[WIDTH * WIDTH] squared = zeroed;
    long[WIDTH] vector = zeroed;
    long[WIDTH] next_vector = zeroed;
    usz dimension = k + 1;
    for (usz index = 0; index < dimension; index += 1) {
        matrix[index * WIDTH + index] = (long)index % modulus;
        if (index > 0) matrix[index * WIDTH + index - 1] = 1;
    }
    vector[0] = 1;

    long exponent = n;
    while (exponent > 0) {
        if (exponent % 2 != 0) {
            for (usz row = 0; row < dimension; row += 1) {
                long total = 0;
                for (usz column = 0; column < dimension; column += 1) {
                    total = (total + matrix[row * WIDTH + column] * vector[column]) % modulus;
                }
                next_vector[row] = total;
            }
            for (usz row = 0; row < dimension; row += 1) vector[row] = next_vector[row];
        }
        exponent /= 2;
        if (exponent > 0) {
            for (usz row = 0; row < dimension; row += 1) {
                for (usz column = 0; column < dimension; column += 1) {
                    long total = 0;
                    for (usz inner = 0; inner < dimension; inner += 1) {
                        total = (total + matrix[row * WIDTH + inner] * matrix[inner * WIDTH + column]) % modulus;
                    }
                    squared[row * WIDTH + column] = total;
                }
            }
            for (usz row = 0; row < dimension; row += 1) {
                for (usz column = 0; column < dimension; column += 1) {
                    matrix[row * WIDTH + column] = squared[row * WIDTH + column];
                    squared[row * WIDTH + column] = 0;
                }
            }
        }
    }
    return vector[k];
}

fn long stirling_number_of_the_second_kind_small_p_large_n(long* input, usz length)
    @export("stirling_number_of_the_second_kind_small_p_large_n") {
    if (input == null || length < 4 || length > 18) return -1;
    long count_value = input[0];
    long modulus = input[1];
    if (count_value < 1 || count_value > (long)MAX_T
            || length != (usz)(2 + 2 * count_value)
            || modulus < 11 || modulus > 97 || !is_prime(modulus)) return -1;

    long result = 0;
    for (usz case_index = 0; case_index < (usz)count_value; case_index += 1) {
        long n = input[2 + 2 * case_index];
        long k_value = input[3 + 2 * case_index];
        if (n < 0 || n > MAX_N || k_value < 0 || k_value > (long)MAX_K || k_value > n) return -1;
        usz k = (usz)k_value;
        long value = stirling_value(n, k, modulus);
        long weight = (long)(case_index + 1) * (long)(case_index + 1);
        result = (result + weight * value) % modulus;
    }
    return result;
}
