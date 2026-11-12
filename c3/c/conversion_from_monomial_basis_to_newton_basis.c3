module conversion_from_monomial_basis_to_newton_basis;

const long MODULUS = 998244353;
const usz MAX_N = 12;
const usz MAX_INPUT = 25;

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long conversion_from_monomial_basis_to_newton_basis(long* input, usz length,
    uint8* output, usz capacity) @export("conversion_from_monomial_basis_to_newton_basis") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 2 * n) return -1;
    for (usz i = 0; i < 2 * n; i++)
        if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;

    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    long[MAX_N] residual = {0};
    long[MAX_N] answer = {0};
    for (usz i = 0; i < n; i++) residual[i] = input[i + 1];

    usz active = n;
    for (usz i = 0; i < n; i++) {
        long node = input[n + 1 + i];
        long value = 0;
        for (usz degree = active; degree > 0; degree--)
            value = (value * node + residual[degree - 1]) % MODULUS;
        answer[i] = value;
        if (active == 1) continue;

        long[MAX_N] quotient = {0};
        quotient[active - 2] = residual[active - 1];
        for (usz degree = active - 2; degree > 0; degree--)
            quotient[degree - 1] = (residual[degree] + node * quotient[degree]) % MODULUS;
        for (usz degree = 0; degree + 1 < active; degree++) residual[degree] = quotient[degree];
        active--;
    }
    for (usz i = 0; i < n; i++) store_le(output, 8 * i, answer[i]);
    return (long)bytes;
}
