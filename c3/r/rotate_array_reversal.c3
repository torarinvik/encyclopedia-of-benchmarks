module rotate_array_reversal;

const usz MAX_ARRAY_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = 1025;

fn void reverse_range(int* values, usz start_value, usz end_value) {
    usz start = start_value;
    usz end = end_value;
    while (start < end) {
        end--;
        if (start >= end) { break; }
        int temporary = values[start];
        values[start] = values[end];
        values[end] = temporary;
        start++;
    }
}

// Rotate by reversing the whole array, then each side of the rotation.
fn long rotate_array_reversal(long* input, usz length, char* output, usz output_capacity) @export("rotate_array_reversal") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) { return -1; }
    long steps = input[0];
    if (steps < -2147483648L || steps > 2147483647L) { return -1; }
    usz count = length - 1;
    int[MAX_ARRAY_LENGTH] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) { return -1; }
        values[index] = (int)value;
    }
    usz output_bytes = count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) { return -2; }
    usz shift = 0;
    if (count != 0) {
        long remainder = steps % (long)count;
        if (remainder < 0) { remainder += (long)count; }
        shift = (usz)remainder;
    }
    reverse_range(&values[0], 0, count);
    reverse_range(&values[0], 0, shift);
    reverse_range(&values[0], shift, count);
    for (usz index = 0; index < count; index++) {
        uint bits = (uint)values[index];
        for (usz byte = 0; byte < 4; byte++) {
            output[index * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return (long)count;
}
