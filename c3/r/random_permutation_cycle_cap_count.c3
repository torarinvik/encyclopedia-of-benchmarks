module random_permutation_cycle_cap_count;

fn long random_permutation_cycle_cap_count(long* input, usz length) @export("random_permutation_cycle_cap_count") {
    if (input == null || length != 2) return -1L;
    long n = input[0];
    long cap = input[1];
    if (n < 1 || n > 20 || cap < 1 || cap > n) return -1L;

    long[21] counts;
    for (int i = 0; i <= 20; i++) counts[i] = 0;
    counts[0] = 1;
    for (long size = 1; size <= n; size++) {
        long total = 0;
        long cycle_choices = 1;
        long limit = size < cap ? size : cap;
        for (long cycle_length = 1; cycle_length <= limit; cycle_length++) {
            if (cycle_length > 1) cycle_choices *= size - cycle_length + 1;
            total += cycle_choices * counts[(int)(size - cycle_length)];
        }
        counts[(int)size] = total;
    }
    return counts[(int)n];
}
