module ways_to_split_array;

const MAX_LENGTH = 100000;
const MAX_VALUE = 100000;

// Count positions where the prefix sum is at least the remaining suffix sum.
fn long ways_to_split_array(long* values, usz length) @export("ways_to_split_array") {
    if (values == null || length < 2 || length > MAX_LENGTH) return -1;
    long total_sum = 0;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -MAX_VALUE || values[index] > MAX_VALUE) return -1;
        total_sum += values[index];
    }
    long prefix_sum = 0;
    long ways = 0;
    for (usz index = 0; index + 1 < length; index++) {
        prefix_sum += values[index];
        if (prefix_sum >= total_sum - prefix_sum) ways++;
    }
    return ways;
}
