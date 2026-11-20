module k_subset_colex_rank_unrank;

fn long choose_small(int n, int k) {
    if (n < 0 || k < 0 || k > n) return 0;
    if (k > n - k) k = n - k;
    long value = 1;
    for (int i = 1; i <= k; i++) value = value * (n - k + i) / i;
    return value;
}

fn void store_i64_le(char* output, usz index, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[index * 8 + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long k_subset_colex_rank_unrank(long* input, usz length, char* output, usz capacity)
        @export("k_subset_colex_rank_unrank") {
    if (input == null || length < 1 || length > 20) return -1;
    long mode = input[0];
    if ((mode != 0 && mode != 1) || length < 3) return -1;
    long raw_n = input[1], raw_k = input[2];
    if (raw_n < 0 || raw_n > 16 || raw_k < 0 || raw_k > raw_n) return -1;
    int n = (int)raw_n, k = (int)raw_k;
    long[16] indices;
    for (int i = 0; i < 16; i++) indices[i] = 0;
    long rank = 0;

    if (mode == 0) {
        if (length != (usz)(3 + k)) return -1;
        for (int i = 0; i < k; i++) {
            long index = input[3 + (usz)i];
            if (index < 0 || index >= n || (i > 0 && indices[i - 1] >= index)) return -1;
            indices[i] = index;
            rank += choose_small((int)index, i + 1);
        }
    } else {
        if (length != 4) return -1;
        rank = input[3];
        if (rank < 0 || rank >= choose_small(n, k)) return -1;
        int upper = n - 1;
        long remainder = rank;
        for (int order = k; order >= 1; order--) {
            int candidate = upper;
            while (candidate >= 0 && choose_small(candidate, order) > remainder) candidate--;
            if (candidate < 0) return -1;
            indices[order - 1] = candidate;
            remainder -= choose_small(candidate, order);
            upper = candidate - 1;
        }
    }

    usz words = (usz)k + 1;
    if (output == null || capacity < words * 8) return -2;
    store_i64_le(output, 0, rank);
    for (int i = 0; i < k; i++) store_i64_le(output, (usz)i + 1, indices[i]);
    return (long)(words * 8);
}
