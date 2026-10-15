module median_of_two_sorted_arrays;

const MAX_TOTAL_LENGTH = 1024;

// Merge two ascending i32 arrays and return twice their exact median.
fn long median_of_two_sorted_arrays(long* input, usz length) @export("median_of_two_sorted_arrays") {
    if (input == null || length < 3 || length > MAX_TOTAL_LENGTH + 2) { return -1; }
    if (input[0] < 0 || input[0] > MAX_TOTAL_LENGTH ||
        input[1] < 0 || input[1] > MAX_TOTAL_LENGTH) { return -1; }
    usz first_count = (usz)input[0];
    usz second_count = (usz)input[1];
    usz total_count = first_count + second_count;
    if (total_count == 0 || total_count > MAX_TOTAL_LENGTH || length != total_count + 2) { return -1; }
    usz second_start = first_count + 2;
    for (usz index = 0; index < first_count; index++) {
        long value = input[index + 2];
        if (value < -2147483648L || value > 2147483647L ||
            (index != 0 && input[index + 1] > value)) { return -1; }
    }
    for (usz index = 0; index < second_count; index++) {
        long value = input[second_start + index];
        if (value < -2147483648L || value > 2147483647L ||
            (index != 0 && input[second_start + index - 1] > value)) { return -1; }
    }

    int[1024] merged;
    usz first_index = 0;
    usz second_index = 0;
    usz written = 0;
    while (first_index < first_count && second_index < second_count) {
        if (input[first_index + 2] <= input[second_start + second_index]) {
            merged[written++] = (int)input[first_index++ + 2];
        } else {
            merged[written++] = (int)input[second_start + second_index++];
        }
    }
    while (first_index < first_count) { merged[written++] = (int)input[first_index++ + 2]; }
    while (second_index < second_count) { merged[written++] = (int)input[second_start + second_index++]; }
    if (total_count % 2 != 0) { return (long)merged[total_count / 2] * 2; }
    return (long)merged[total_count / 2 - 1] + merged[total_count / 2];
}
