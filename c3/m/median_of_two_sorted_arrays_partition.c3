module median_of_two_sorted_arrays_partition;

const MAX_ARRAY_LENGTH = 1000;
const VALUE_MIN = -1000000L;
const VALUE_MAX = 1000000L;

// Return twice the exact median using a binary partition of the shorter array.
fn long median_of_two_sorted_arrays_partition(long* input, usz length) @export("median_of_two_sorted_arrays_partition") {
    if (input == null || length < 3 || length > 2 * MAX_ARRAY_LENGTH + 2) { return -2000001; }
    if (input[0] < 0 || input[0] > MAX_ARRAY_LENGTH ||
        input[1] < 0 || input[1] > MAX_ARRAY_LENGTH) { return -2000001; }

    usz first_count = (usz)input[0];
    usz second_count = (usz)input[1];
    usz total_count = first_count + second_count;
    if (total_count == 0 || total_count > 2 * MAX_ARRAY_LENGTH || length != total_count + 2) { return -2000001; }

    long* first = input + 2;
    long* second = first + first_count;
    for (usz index = 0; index < first_count; index++) {
        long value = input[index + 2];
        if (value < VALUE_MIN || value > VALUE_MAX ||
            (index > 0 && input[index + 1] > value)) { return -2000001; }
    }
    for (usz index = 0; index < second_count; index++) {
        long value = second[index];
        if (value < VALUE_MIN || value > VALUE_MAX ||
            (index > 0 && second[index - 1] > value)) { return -2000001; }
    }

    usz short_count = first_count;
    usz long_count = second_count;
    if (short_count > long_count) {
        long* temporary_values = first;
        first = second;
        second = temporary_values;
        short_count = second_count;
        long_count = first_count;
    }

    usz low = 0;
    usz high = short_count;
    usz left_count = (total_count + 1) / 2;
    while (low <= high) {
        usz first_cut = low + (high - low) / 2;
        usz second_cut = left_count - first_cut;
        long first_left = first_cut == 0 ? -1000001L : first[first_cut - 1];
        long first_right = first_cut == short_count ? 1000001L : first[first_cut];
        long second_left = second_cut == 0 ? -1000001L : second[second_cut - 1];
        long second_right = second_cut == long_count ? 1000001L : second[second_cut];

        if (first_left <= second_right && second_left <= first_right) {
            long left_max = first_left > second_left ? first_left : second_left;
            if (total_count % 2 != 0) { return left_max * 2; }
            long right_min = first_right < second_right ? first_right : second_right;
            return left_max + right_min;
        }
        if (first_left > second_right) {
            if (first_cut == 0) { return -2000001; }
            high = first_cut - 1;
        } else {
            low = first_cut + 1;
        }
    }
    return -2000001;
}
