module merge_two_sorted_lists;

const MAX_TOTAL_LENGTH = 1024;

// Linear merge over two packed ascending i32 sequences.
fn long merge_two_sorted_lists(long* input, usz length, char* output,
        usz output_capacity) @export("merge_two_sorted_lists") {
    if (input == null || length < 2 || length > MAX_TOTAL_LENGTH + 2) { return -1; }
    if (input[0] < 0 || input[0] > MAX_TOTAL_LENGTH ||
        input[1] < 0 || input[1] > MAX_TOTAL_LENGTH) { return -1; }
    usz first_count = (usz)input[0];
    usz second_count = (usz)input[1];
    if (first_count + second_count > MAX_TOTAL_LENGTH ||
        length != first_count + second_count + 2) { return -1; }
    for (usz index = 0; index < first_count; index++) {
        long value = input[index + 2];
        if (value < -2147483648L || value > 2147483647L ||
            (index != 0 && input[index + 1] > value)) { return -1; }
    }
    usz second_start = first_count + 2;
    for (usz index = 0; index < second_count; index++) {
        long value = input[second_start + index];
        if (value < -2147483648L || value > 2147483647L ||
            (index != 0 && input[second_start + index - 1] > value)) { return -1; }
    }

    usz total_count = first_count + second_count;
    usz output_bytes = total_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) { return -2; }
    usz first_index = 0;
    usz second_index = 0;
    for (usz written = 0; written < total_count; written++) {
        long value;
        if (first_index == first_count) {
            value = input[second_start + second_index];
            second_index++;
        } else if (second_index == second_count) {
            value = input[first_index + 2];
            first_index++;
        } else if (input[first_index + 2] <= input[second_start + second_index]) {
            value = input[first_index + 2];
            first_index++;
        } else {
            value = input[second_start + second_index];
            second_index++;
        }
        uint bits = (uint)(int)value;
        for (usz byte = 0; byte < 4; byte++) {
            output[written * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return (long)total_count;
}
