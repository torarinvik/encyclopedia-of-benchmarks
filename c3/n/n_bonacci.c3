module n_bonacci;

// Return the final term of a bounded N-bonacci sequence.
fn long n_bonacci(long* values, usz length) @export("n_bonacci") {
    if (values == null || length != 2) return -1;
    long order_value = values[0];
    long count_value = values[1];
    if (order_value < 1 || count_value <= order_value || count_value > 64) return -1;
    usz order = (usz)order_value;
    usz count = (usz)count_value;
    long[64] terms;
    for (usz i = 0; i < 64; i++) terms[i] = 0;
    terms[order - 1] = 1;
    terms[order] = 1;
    for (usz i = order + 1; i < count; i++) {
        terms[i] = 2 * terms[i - 1] - terms[i - 1 - order];
    }
    return terms[count - 1];
}
