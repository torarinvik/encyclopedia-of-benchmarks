module max_product_subarray;

const long INVALID_RESULT = (-9223372036854775807L - 1L);

fn long max_product_subarray(long* values, usz length) @export("max_product_subarray") {
    if (length > 9 || (length > 0 && values == null)) return INVALID_RESULT;
    if (length == 0) return 0;
    if (values[0] < -10 || values[0] > 10) return INVALID_RESULT;
    long max_now = values[0], min_now = values[0], max_product = values[0];
    for (usz i = 1; i < length; i++) {
        long value = values[i];
        if (value < -10 || value > 10) return INVALID_RESULT;
        if (value < 0) { long swap = max_now; max_now = min_now; min_now = swap; }
        long product = max_now * value;
        max_now = value > product ? value : product;
        product = min_now * value;
        min_now = value < product ? value : product;
        if (max_now > max_product) max_product = max_now;
    }
    return max_product;
}
