module bostan_mori_recurrence_term;

const int MAX_ORDER = 8;
const long MODULUS = 998244353;

fn void convolve(long* left, int left_len, long* right, int right_len, long* product) {
    for (int i = 0; i < left_len + right_len - 1; i++) product[i] = 0;
    for (int i = 0; i < left_len; i++) {
        for (int j = 0; j < right_len; j++) {
            int at = i + j;
            product[at] = (product[at] + left[i] * right[j]) % MODULUS;
        }
    }
}

fn long bostan_mori_recurrence_term(long* input, usz length) @export("bostan_mori_recurrence_term") {
    if (input == null || length < 2) return -1;
    long order_word = input[0], index_word = input[1];
    if (order_word < 1 || order_word > MAX_ORDER || index_word < 0
            || index_word > 1000000000000000000) return -1;
    int order = (int)order_word;
    if (length != (usz)(2 + 2 * order)) return -1;

    long[MAX_ORDER] recurrence = {};
    long[MAX_ORDER] initial = {};
    long[MAX_ORDER] numerator = {};
    long[MAX_ORDER + 1] denominator = {};
    denominator[0] = 1;
    for (int i = 0; i < order; i++) {
        recurrence[i] = input[2 + i];
        initial[i] = input[2 + order + i];
        if (recurrence[i] < 0 || recurrence[i] >= MODULUS
                || initial[i] < 0 || initial[i] >= MODULUS) return -1;
        denominator[i + 1] = recurrence[i] == 0 ? 0 : MODULUS - recurrence[i];
    }

    long[MAX_ORDER * 2 + 1] product = {};
    convolve(&initial[0], order, &denominator[0], order + 1, &product[0]);
    for (int i = 0; i < order; i++) numerator[i] = product[i];
    long index = index_word;
    while (index > 0) {
        long[MAX_ORDER + 1] denominator_negative = {};
        long[MAX_ORDER * 2 + 1] numerator_product = {};
        long[MAX_ORDER * 2 + 1] denominator_product = {};
        for (int i = 0; i <= order; i++) {
            denominator_negative[i] = (i & 1) == 0 || denominator[i] == 0
                    ? denominator[i] : MODULUS - denominator[i];
        }
        convolve(&numerator[0], order, &denominator_negative[0], order + 1, &numerator_product[0]);
        convolve(&denominator[0], order + 1, &denominator_negative[0], order + 1, &denominator_product[0]);
        int parity = (int)(index & 1);
        for (int i = 0; i < order; i++) numerator[i] = numerator_product[2 * i + parity];
        for (int i = 0; i <= order; i++) denominator[i] = denominator_product[2 * i];
        index >>= 1;
    }
    return numerator[0];
}
