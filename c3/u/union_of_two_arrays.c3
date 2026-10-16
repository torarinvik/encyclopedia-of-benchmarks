module union_of_two_arrays;

const usz MAX_ARRAY_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 2 * (MAX_ARRAY_LENGTH + 1);
const usz BYTES_PER_VALUE = 4;

fn void store_i32_le(char* output, usz position, long value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < BYTES_PER_VALUE; byte += 1) {
        output[position + byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

fn long union_of_two_arrays(long* input, usz length, char* output, usz output_capacity)
    @export("union_of_two_arrays") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long first_length_value = input[0];
    if (first_length_value < 0 || first_length_value > (long)MAX_ARRAY_LENGTH) return -1;
    usz first_length = (usz)first_length_value;
    usz second_length_position = 1 + first_length;
    if (second_length_position >= length) return -1;
    long second_length_value = input[second_length_position];
    if (second_length_value < 0 || second_length_value > (long)MAX_ARRAY_LENGTH) return -1;
    usz second_length = (usz)second_length_value;
    usz second_start = second_length_position + 1;
    if (second_length != length - second_start) return -1;

    for (usz index = 0; index < first_length; index += 1) {
        long value = input[1 + index];
        if (value < -2147483648L || value > 2147483647L) return -1;
        if (index > 0 && input[index] > value) return -1;
    }
    for (usz index = 0; index < second_length; index += 1) {
        long value = input[second_start + index];
        if (value < -2147483648L || value > 2147483647L) return -1;
        if (index > 0 && input[second_start + index - 1] > value) return -1;
    }

    usz maximum_result = first_length + second_length;
    if (output_capacity < maximum_result * BYTES_PER_VALUE || (maximum_result > 0 && output == null)) return -2;
    usz first_index = 0;
    usz second_index = 0;
    usz result_count = 0;
    long previous_value = 0;
    while (first_index < first_length || second_index < second_length) {
        long value;
        if (first_index == first_length) {
            value = input[second_start + second_index];
            second_index += 1;
        } else if (second_index == second_length) {
            value = input[1 + first_index];
            first_index += 1;
        } else {
            long first = input[1 + first_index];
            long second = input[second_start + second_index];
            if (first < second) {
                value = first;
                first_index += 1;
            } else if (first > second) {
                value = second;
                second_index += 1;
            } else {
                value = first;
                first_index += 1;
                second_index += 1;
            }
        }
        if (result_count == 0 || value != previous_value) {
            store_i32_le(output, result_count * BYTES_PER_VALUE, value);
            previous_value = value;
            result_count += 1;
        }
    }
    return (long)result_count;
}
