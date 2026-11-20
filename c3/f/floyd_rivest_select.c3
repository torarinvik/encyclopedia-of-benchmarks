module floyd_rivest_select;

const usz MAX_VALUES = 64;
const usz MAX_INPUT_LENGTH = 67;
const usz SAMPLE_THRESHOLD = 24;

extern fn double sqrt(double value);
extern fn double log(double value);
extern fn double exp(double value);
extern fn double floor(double value);
extern fn double ceil(double value);

fn long select_kth(long* values, usz left, usz right, usz target) {
    while (true) {
        if (right - left > SAMPLE_THRESHOLD) {
            usz size = right - left + 1;
            usz relative_rank = target - left + 1;
            double z = sqrt(log((double)size));
            double sample_size = 0.5 * exp(2.0 * z / 3.0);
            double direction = 0.0;
            if (2 * relative_rank < size) direction = -1.0;
            else if (2 * relative_rank > size) direction = 1.0;
            double spread = 0.5 * sqrt(
                z * sample_size * ((double)size - sample_size) / (double)size
            ) * direction;
            double lower_estimate = (double)target
                - (double)relative_rank * sample_size / (double)size + spread;
            double upper_estimate = (double)target
                + (double)(size - relative_rank) * sample_size / (double)size + spread;

            long sample_left_value = (long)floor(lower_estimate);
            if (sample_left_value < (long)left) sample_left_value = (long)left;
            if (sample_left_value < (long)target) sample_left_value = (long)target;
            long sample_right_value = (long)ceil(upper_estimate);
            if (sample_right_value > (long)right) sample_right_value = (long)right;
            if (sample_right_value < (long)target) sample_right_value = (long)target;
            (void)select_kth(values, (usz)sample_left_value, (usz)sample_right_value, target);
        }

        long pivot = values[target];
        usz less = left;
        usz scan = left;
        usz greater = right + 1;
        while (scan < greater) {
            if (values[scan] < pivot) {
                long temporary = values[less];
                values[less] = values[scan];
                values[scan] = temporary;
                less++;
                scan++;
            } else if (values[scan] > pivot) {
                greater--;
                long temporary = values[greater];
                values[greater] = values[scan];
                values[scan] = temporary;
            } else {
                scan++;
            }
        }
        if (target < less) right = less - 1;
        else if (target >= greater) left = greater;
        else return pivot;
    }
}

fn long floyd_rivest_select(long* input, usz length) @export("floyd_rivest_select") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    long rank_value = input[1];
    if (count_value < 1 || count_value > (long)MAX_VALUES || rank_value < 0 ||
        rank_value >= count_value || length != (usz)count_value + 2) return -1;

    usz count = (usz)count_value;
    long[MAX_VALUES] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 2];
        if (value < 0 || value > 2147483647) return -1;
        for (usz previous = 0; previous < index; previous++) {
            if (values[previous] == value) return -1;
        }
        values[index] = value;
    }
    return select_kth(&values[0], 0, count - 1, (usz)rank_value);
}
