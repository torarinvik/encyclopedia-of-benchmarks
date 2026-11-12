module stirling_number_of_the_first_kind_small_p_large_n;

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
    long quotient = n / modulus;
    long remainder = n % modulus;
    if (quotient > (long)k) return 0;
    usz target = k - (usz)quotient;
    long[WIDTH] coefficients = zeroed;
    coefficients[0] = 1;
    for (long residue = 0; residue < remainder; residue += 1) {
        for (usz degree = target; degree > 0; degree -= 1) {
            coefficients[degree] = (coefficients[degree - 1] - residue * coefficients[degree]) % modulus;
            if (coefficients[degree] < 0) coefficients[degree] += modulus;
        }
        coefficients[0] = (-residue * coefficients[0]) % modulus;
        if (coefficients[0] < 0) coefficients[0] += modulus;
    }
    long coefficient = coefficients[target];
    if (quotient % 2 == 0 || coefficient == 0) return coefficient;
    return modulus - coefficient;
}

fn long stirling_number_of_the_first_kind_small_p_large_n(long* input, usz length)
    @export("stirling_number_of_the_first_kind_small_p_large_n") {
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
        long value = stirling_value(n, (usz)k_value, modulus);
        long next = (long)(case_index + 1);
        result = (result + next * next * value) % modulus;
    }
    return result;
}
