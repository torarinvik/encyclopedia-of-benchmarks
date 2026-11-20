module linear_partition_minimax;

const usz MAX_PARSEABLE_INPUT_LENGTH = 35;
const usz MAX_N = 32;

fn bool feasible(long* input, usz n, usz groups, long limit) {
    usz used_groups = 1;
    long current_sum = 0;
    for (usz i = 0; i < n; i++) {
        long value = input[i + 2];
        if (current_sum + value > limit) {
            used_groups++;
            current_sum = value;
            if (used_groups > groups) return false;
        } else {
            current_sum += value;
        }
    }
    return true;
}

fn long linear_partition_minimax(long* input, usz length)
    @export("linear_partition_minimax") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 1 || input[1] > input[0]) return -1;
    usz n = (usz)input[0];
    usz groups = (usz)input[1];
    if (length != n + 2) return -1;

    long low = 0, high = 0;
    for (usz i = 0; i < n; i++) {
        long value = input[i + 2];
        if (value < 0 || value > 1000) return -1;
        if (value > low) low = value;
        high += value;
    }
    while (low < high) {
        long middle = low + (high - low) / 2;
        if (feasible(input, n, groups, middle)) high = middle;
        else low = middle + 1;
    }
    return low;
}
