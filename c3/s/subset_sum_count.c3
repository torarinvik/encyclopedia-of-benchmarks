module subset_sum_count;

// Count indexed signed subsets that reach the requested sum.
fn long subset_sum_count(long* input, usz length) @export("subset_sum_count")
{
    if (length == 0 || length > 25) return -1;
    long target = input[0];
    if (target < -6144 || target > 6144) return -1;
    for (usz index = 1; index < length; index++) {
        if (input[index] < -256 || input[index] > 256) return -1;
    }
    int[12289] ways;
    for (usz index = 0; index < 12289; index++) ways[index] = 0;
    ways[6144] = 1;
    long low = 0;
    long high = 0;
    for (usz index = 1; index < length; index++) {
        long value = input[index];
        if (value > 0) {
            for (long sum = high; sum >= low; sum--) ways[(usz)(sum + value + 6144)] += ways[(usz)(sum + 6144)];
            high += value;
        } else if (value < 0) {
            for (long sum = low; sum <= high; sum++) ways[(usz)(sum + value + 6144)] += ways[(usz)(sum + 6144)];
            low += value;
        } else {
            for (long sum = low; sum <= high; sum++) ways[(usz)(sum + 6144)] *= 2;
        }
    }
    return (long)ways[(usz)(target + 6144)];
}
