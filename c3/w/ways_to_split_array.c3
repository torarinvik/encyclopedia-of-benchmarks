module ways_to_split_array;

const MAX_LENGTH = 100000;
const MAX_VALUE = 100000;

// Count positions where the prefix sum is at least the remaining suffix sum.
fn long ways_to_split_array(long* values, usz length) @export("ways_to_split_array") {
    if (values == null || length < 2 || length > MAX_LENGTH) return -1;
    ulong total = 0;
    ulong largest_biased_value = 0;
    for (usz index = 0; index < length; index++) {
        ulong value = (ulong)values[index];
        ulong biased = value + MAX_VALUE;
        largest_biased_value = biased > largest_biased_value ? biased : largest_biased_value;
        total += value;
    }
    if (largest_biased_value > 2 * MAX_VALUE) return -1;
    long signed_total = (long)total;
    long threshold = signed_total / 2 + (signed_total > 0 && signed_total % 2 != 0 ? 1 : 0);
    ulong prefix = 0;
    long ways = 0;
    for (usz index = 0; index < length - 1; index++) {
        prefix += (ulong)values[index];
        if ((long)prefix >= threshold) ways++;
    }
    return ways;
}
