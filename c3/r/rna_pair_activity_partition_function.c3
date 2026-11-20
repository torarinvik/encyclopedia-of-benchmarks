module rna_pair_activity_partition_function;

const usz MAX_SEQUENCE_LENGTH = 16;
const usz MAX_PARSEABLE_LENGTH = 122;

fn usz pair_input_index(usz n, usz left, usz right) {
    usz preceding = left * (2 * n - left - 1) / 2;
    return 1 + preceding + (right - left - 1);
}

fn long rna_pair_activity_partition_function(long* input, usz length)
    @export("rna_pair_activity_partition_function") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_SEQUENCE_LENGTH) return -1;
    usz n = (usz)n_value;
    usz expected_length = n == 0 ? 1 : 1 + n * (n - 1) / 2;
    if (length != expected_length) return -1;
    for (usz index = 1; index < length; index += 1)
        if (input[index] < 0 || input[index] > 3) return -1;
    if (n == 0) return 1;

    long[MAX_SEQUENCE_LENGTH][MAX_SEQUENCE_LENGTH] table = zeroed;
    for (usz span = 1; span <= n; span += 1) {
        for (usz left = 0; left + span <= n; left += 1) {
            usz right = left + span - 1;
            long total = left == right ? 1 : table[left][right - 1];
            for (usz partner = left; partner < right; partner += 1) {
                long activity = input[pair_input_index(n, partner, right)];
                long before = partner == left ? 1 : table[left][partner - 1];
                long inside = partner + 1 >= right ? 1 : table[partner + 1][right - 1];
                total += before * inside * activity;
            }
            table[left][right] = total;
        }
    }
    return table[0][n - 1];
}
