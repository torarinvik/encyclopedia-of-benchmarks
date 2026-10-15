module squares_of_a_sorted_array;

const usz MAX_ARRAY_LENGTH = 10000;

// Square a sorted array and emit the results in ascending order.
fn long squares_of_a_sorted_array(long* input, usz length, char* output,
                                  usz output_capacity) @export("squares_of_a_sorted_array") {
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == null)) { return -1; }
    for (usz index = 0; index < length; index++) {
        if (input[index] < -10000 || input[index] > 10000) { return -1; }
        if (index != 0 && input[index - 1] > input[index]) { return -1; }
    }
    usz output_bytes = length * 8;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) { return -2; }

    usz left = 0;
    usz right = length;
    usz destination = length;
    while (destination != 0) {
        destination--;
        long left_value = input[left];
        long right_value = input[right - 1];
        long left_magnitude = left_value < 0 ? -left_value : left_value;
        long right_magnitude = right_value < 0 ? -right_value : right_value;
        long value;
        if (left_magnitude > right_magnitude) {
            value = left_value;
            left++;
        } else {
            value = right_value;
            right--;
        }
        ulong square = (ulong)(value * value);
        for (usz byte = 0; byte < 8; byte++) {
            output[destination * 8 + byte] = (char)((square >> (byte * 8)) & 255);
        }
    }
    return (long)length;
}
