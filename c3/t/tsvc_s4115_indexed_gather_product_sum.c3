// Clean-room bounded port of TSVC s4115; see package README for provenance.
module tsvc_s4115_indexed_gather_product_sum;

const usz MAX_N = 64;
const long MAX_VALUE = 1000000L;

long tsvc_s4115_indexed_gather_product_sum(long* input, usz length)
        @export("tsvc_s4115_indexed_gather_product_sum") {
    if (input == null || length < 4 || length > 193) return -1;
    long n_raw = input[0];
    if (n_raw < 1 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + 3 * n) return -1;

    for (usz i = 0; i < n; i++) {
        long index = input[1 + i];
        long a_value = input[1 + n + i];
        long b_value = input[1 + 2 * n + i];
        if (index < 0 || index >= n_raw) return -1;
        if (a_value < 0 || a_value > MAX_VALUE || b_value < 0 || b_value > MAX_VALUE) return -1;
    }

    long sum = 0;
    for (usz i = 0; i < n; i++) {
        usz index = (usz)input[1 + i];
        sum += input[1 + n + i] * input[1 + 2 * n + index];
    }
    return sum;
}
