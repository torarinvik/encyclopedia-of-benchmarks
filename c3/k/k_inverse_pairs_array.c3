module k_inverse_pairs_array;

const usz MAX_N = 128;
const usz MAX_K = 512;
const long MODULUS = 1000000007L;

fn long k_inverse_pairs_array(long* input, usz length)
        @export("k_inverse_pairs_array") {
    if (input == null || length < 1 || length > 3 || length != 2) return -1;
    long n_value = input[0], k_value = input[1];
    if (n_value < 0 || n_value > (long)MAX_N || k_value < 0 || k_value > (long)MAX_K) return -1;
    usz n = (usz)n_value, k = (usz)k_value;
    if (k > n * (n > 0 ? n - 1 : 0) / 2) return 0;

    long[MAX_K + 1] previous = zeroed, current = zeroed;
    previous[0] = 1;
    for (usz size = 1; size <= n; size++) {
        long window = 0;
        for (usz inversions = 0; inversions <= k; inversions++) {
            window += previous[inversions];
            if (inversions >= size) window -= previous[inversions - size];
            window %= MODULUS;
            if (window < 0) window += MODULUS;
            current[inversions] = window;
        }
        for (usz inversions = 0; inversions <= k; inversions++) previous[inversions] = current[inversions];
    }
    return previous[k];
}
