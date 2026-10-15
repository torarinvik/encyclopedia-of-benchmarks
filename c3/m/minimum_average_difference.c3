module minimum_average_difference;

const MAX_LENGTH = 100000;
const MAX_VALUE = 100000;

// Return the earliest split with the smallest difference of integer averages.
fn long minimum_average_difference(long* values, usz length) @export("minimum_average_difference") {
    if (values == null || length == 0 || length > MAX_LENGTH) { return -1; }
    long total_sum = 0;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > MAX_VALUE) { return -1; }
        total_sum += values[index];
    }
    long prefix_sum = 0;
    long best_difference = 9223372036854775807;
    usz best_index = 0;
    for (usz index = 0; index < length; index++) {
        prefix_sum += values[index];
        long left_average = prefix_sum / (long)(index + 1);
        usz suffix_length = length - index - 1;
        long right_average = suffix_length == 0 ? 0 : (total_sum - prefix_sum) / (long)suffix_length;
        long difference = left_average >= right_average ? left_average - right_average : right_average - left_average;
        if (difference < best_difference) {
            best_difference = difference;
            best_index = index;
        }
    }
    return (long)best_index;
}
