module merge_sorted;

const usz MAX_ARRAY_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_ARRAY_LENGTH;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1;
const long MIN_VALUE = -1000000;
const long MAX_VALUE = 1000000;
const long CHECKSUM_OFFSET = 1000001;

fn long merge_sorted(long* values, usz length) @export("merge_sorted") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > (long)MAX_ARRAY_LENGTH ||
        values[1] < 0 || values[1] > (long)MAX_ARRAY_LENGTH) return -1;
    left_count: usz = (usz)values[0];
    right_count: usz = (usz)values[1];
    if (length != 2 + left_count + right_count) return -1;
    right_start: usz = 2 + left_count;

    for (usz index = 0; index < left_count; index++) {
        value: long = values[2 + index];
        if (value < MIN_VALUE || value > MAX_VALUE ||
            (index > 0 && values[2 + index - 1] > value)) return -1;
    }
    for (usz index = 0; index < right_count; index++) {
        value: long = values[right_start + index];
        if (value < MIN_VALUE || value > MAX_VALUE ||
            (index > 0 && values[right_start + index - 1] > value)) return -1;
    }

    left_index: mutable usz = 0;
    right_index: mutable usz = 0;
    output_index: mutable long = 0;
    checksum: mutable long = 0;
    while (left_index < left_count && right_index < right_count) {
        value: mutable long = 0;
        if (values[2 + left_index] <= values[right_start + right_index]) {
            value = values[2 + left_index];
            left_index++;
        } else {
            value = values[right_start + right_index];
            right_index++;
        }
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET);
        output_index++;
    }
    while (left_index < left_count) {
        value: long = values[2 + left_index];
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET);
        left_index++;
        output_index++;
    }
    while (right_index < right_count) {
        value: long = values[right_start + right_index];
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET);
        right_index++;
        output_index++;
    }
    checksum
}
