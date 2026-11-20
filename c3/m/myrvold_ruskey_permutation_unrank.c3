module myrvold_ruskey_permutation_unrank;

fn void mr_write(char* output, usz index, ulong value) {
    for (usz byte = 0; byte < 8; byte++)
        output[index * 8 + byte] = (char)(value >> (byte * 8));
}

fn long myrvold_ruskey_permutation_unrank(long* input, usz length,
                                           char* output, usz capacity)
    @export("myrvold_ruskey_permutation_unrank") {
    if (input == null || length < 2 || length > 3) return -1;
    if (length != 2) return -1;
    long n_value = input[0];
    long rank_value = input[1];
    if (n_value < 0 || n_value > 8 || rank_value < 0) return -1;
    usz n = (usz)n_value;
    long factorial = 1;
    for (usz factor = 2; factor <= n; factor++) factorial *= (long)factor;
    if (rank_value >= factorial) return -1;

    usz required = 8 * n;
    if (output == null || capacity < required) return -2;
    long[8] permutation;
    for (usz i = 0; i < n; i++) permutation[i] = (long)i;
    long remainder = rank_value;
    usz size = n;
    while (size > 0) {
        usz choice = (usz)(remainder % (long)size);
        remainder /= (long)size;
        usz last = size - 1;
        long held = permutation[last];
        permutation[last] = permutation[choice];
        permutation[choice] = held;
        size--;
    }
    for (usz i = 0; i < n; i++) mr_write(output, i, (ulong)permutation[i]);
    return (long)required;
}
