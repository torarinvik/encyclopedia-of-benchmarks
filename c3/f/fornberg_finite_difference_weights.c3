module fornberg_finite_difference_weights;

const usz MAX_INPUT_LENGTH = 12;
const usz MAX_NODES = 8;
const long MODULUS = 998244353;

fn long mod_norm(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long fornberg_finite_difference_weights(long *input, usz length, char *output, usz capacity)
    @export("fornberg_finite_difference_weights") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], order = input[1], target = input[2];
    if (n_value < 1 || n_value > (long)MAX_NODES || order < 0 || order > 3
        || order >= n_value || length != (usz)n_value + 3) return -1;
    usz n = (usz)n_value;
    if (target < 0 || target >= MODULUS) return -1;
    for (usz i = 0; i < n; i++) {
        long node = input[3 + i];
        if (node < 0 || node >= MODULUS) return -1;
        for (usz j = 0; j < i; j++) if (node == input[3 + j]) return -1;
    }

    long table[8][4] = {};
    table[0][0] = 1;
    long previous_product = 1;
    for (usz new_index = 1; new_index < n; new_index++) {
        long old_last[4] = {};
        for (usz d = 0; d < 4; d++) old_last[d] = table[new_index - 1][d];
        long product = 1;
        long node = input[3 + new_index];
        long factor = mod_norm(node - target);
        long max_d = new_index < (usz)order ? (long)new_index : order;
        for (usz old_index = 0; old_index < new_index; old_index++) {
            long difference = mod_norm(node - input[3 + old_index]);
            product = product * difference % MODULUS;
            long inverse_difference = mod_pow(difference, MODULUS - 2);
            for (long d = max_d; d >= 0; d--) {
                long lower = d == 0 ? 0 : table[old_index][(usz)(d - 1)];
                long numerator = mod_norm(factor * table[old_index][(usz)d] - d * lower);
                table[old_index][(usz)d] = numerator * inverse_difference % MODULUS;
            }
        }
        long product_inverse = mod_pow(product, MODULUS - 2);
        long last_factor = mod_norm(input[2 + new_index] - target);
        for (long d = 0; d <= max_d; d++) {
            long lower = d == 0 ? 0 : old_last[(usz)(d - 1)];
            long numerator = mod_norm(d * lower - last_factor * old_last[(usz)d]);
            table[new_index][(usz)d] = previous_product * product_inverse % MODULUS * numerator % MODULUS;
        }
        previous_product = product;
    }

    usz required = 8 * (n + 1);
    if (output == null || capacity < required) return -2;
    store_i64_le(output, 0, n_value);
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * (i + 1), table[i][(usz)order]);
    return (long)required;
}
