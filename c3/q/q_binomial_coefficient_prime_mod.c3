module q_binomial_coefficient_prime_mod;

const long MAX_MODULUS = 31;
const usz MAX_T = 16;
const usz MAX_N = 16;
const usz MAX_PARSEABLE_INPUT_LENGTH = 36;

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor <= value / divisor; divisor += 1) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long modular_power(long base, usz exponent, long modulus) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent = exponent >> 1;
    }
    return result;
}

fn long q_binomial_coefficient_prime_mod(
    long* input, usz length, char* output, usz capacity)
    @export("q_binomial_coefficient_prime_mod") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) {
        return -1;
    }
    long count_value = input[0];
    long modulus = input[1];
    long q_value = input[2];
    if (count_value < 1 || count_value > (long)MAX_T
        || modulus < 2 || modulus > MAX_MODULUS || !is_prime(modulus)
        || q_value < 0 || q_value >= modulus) {
        return -1;
    }
    usz count = (usz)count_value;
    if (length != 3 + 2 * count) return -1;

    usz max_n = 0;
    for (usz query = 0; query < count; query += 1) {
        long n_value = input[3 + 2 * query];
        long k_value = input[4 + 2 * query];
        if (n_value < 0 || n_value > (long)MAX_N
            || k_value < 0 || k_value > (long)MAX_N
            || n_value >= modulus || k_value >= modulus) {
            return -1;
        }
        if ((usz)n_value > max_n) max_n = (usz)n_value;
    }
    if (output == null || capacity < count) return -2;

    long[MAX_N + 1][MAX_N + 1] table = zeroed;
    table[0][0] = 1;
    for (usz n = 1; n <= max_n; n += 1) {
        table[n][0] = 1;
        for (usz k = 1; k <= n; k += 1) {
            long previous_same = k < n ? table[n - 1][k] : 0;
            long weight = modular_power(q_value, n - k, modulus);
            table[n][k] = (previous_same + weight * table[n - 1][k - 1])
                % modulus;
        }
    }

    for (usz query = 0; query < count; query += 1) {
        usz n = (usz)input[3 + 2 * query];
        usz k = (usz)input[4 + 2 * query];
        output[query] = (char)(k > n ? 0 : table[n][k]);
    }
    return (long)count;
}
