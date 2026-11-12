module multipoint_evaluation;

const long MODULUS = 998244353;
const usz MAX_N = 8, MAX_M = 8, LEAF_BASE = 8, NODE_CAPACITY = 16, COEFFICIENT_CAPACITY = 9, MAX_INPUT = 18;

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255ul); bits >>= 8; }
}

fn usz trim(long* polynomial, usz length) {
    while (length > 1 && polynomial[length - 1] == 0) length--;
    return length;
}

fn usz multiply(long* left, usz left_length, long* right, usz right_length, long* product) {
    usz length = left_length + right_length - 1;
    for (usz i = 0; i < length; i++) product[i] = 0;
    for (usz i = 0; i < left_length; i++)
        for (usz j = 0; j < right_length; j++) product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
    return length;
}

fn usz polynomial_remainder(long* dividend, usz dividend_length, long* divisor, usz divisor_length, long* result) {
    if (divisor_length == 1 && divisor[0] == 1) { result[0] = 0; return 1; }
    for (usz i = 0; i < dividend_length; i++) result[i] = dividend[i];
    usz length = trim(result, dividend_length);
    while (length >= divisor_length) {
        usz shift = length - divisor_length;
        long factor = result[length - 1];
        for (usz degree = 0; degree < divisor_length; degree++) {
            usz slot = shift + degree;
            result[slot] = (result[slot] - factor * divisor[degree]) % MODULUS;
            if (result[slot] < 0) result[slot] += MODULUS;
        }
        length = trim(result, length);
    }
    return length;
}

fn long multipoint_evaluation(long* input, usz length, uint8* output, usz capacity)
    @export("multipoint_evaluation") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 1 || input[1] > (long)MAX_M) return -1;
    usz n = (usz)input[0], m = (usz)input[1];
    if (length != 2 + n + m) return -1;
    for (usz i = 0; i < n + m; i++) if (input[2 + i] < 0 || input[2 + i] >= MODULUS) return -1;
    if (input[1 + n] == 0) return -1;
    usz bytes = 8 * m;
    if (output == null || capacity < bytes) return -2;

    long[NODE_CAPACITY][COEFFICIENT_CAPACITY] products = zeroed;
    long[NODE_CAPACITY][COEFFICIENT_CAPACITY] remainders = zeroed;
    usz[NODE_CAPACITY] product_lengths = zeroed, remainder_lengths = zeroed, starts = zeroed, spans = zeroed;
    for (usz node = 1; node < NODE_CAPACITY; node++) { products[node][0] = 1; product_lengths[node] = 1; }
    for (usz i = 0; i < m; i++) {
        usz leaf = LEAF_BASE + i;
        products[leaf][0] = input[2 + n + i] == 0 ? 0 : MODULUS - input[2 + n + i];
        products[leaf][1] = 1;
        product_lengths[leaf] = 2;
    }
    for (usz node = LEAF_BASE - 1; node > 0; node--)
        product_lengths[node] = multiply(&products[2 * node][0], product_lengths[2 * node],
            &products[2 * node + 1][0], product_lengths[2 * node + 1], &products[node][0]);

    starts[1] = 0;
    spans[1] = LEAF_BASE;
    for (usz node = 1; node < LEAF_BASE; node++) {
        spans[2 * node] = spans[node] / 2;
        spans[2 * node + 1] = spans[node] / 2;
        starts[2 * node] = starts[node];
        starts[2 * node + 1] = starts[node] + spans[node] / 2;
    }
    remainder_lengths[1] = polynomial_remainder(input + 2, n, &products[1][0], product_lengths[1], &remainders[1][0]);
    for (usz node = 1; node < LEAF_BASE; node++)
        for (usz side = 0; side < 2; side++) {
            usz child = 2 * node + side;
            if (starts[child] < m)
                remainder_lengths[child] = polynomial_remainder(&remainders[node][0], remainder_lengths[node],
                    &products[child][0], product_lengths[child], &remainders[child][0]);
        }
    for (usz i = 0; i < m; i++) store_le(output, 8 * i, remainders[LEAF_BASE + i][0]);
    return (long)bytes;
}
