module permute_string;

const usz MAX_N = 7;
const usz MAX_INPUT_LENGTH = 9;
const usz MAX_OUTPUT_BYTES = 35280;

fn usz factorial(usz value) {
    usz result = 1;
    for (usz factor = 2; factor <= value; factor++) result *= factor;
    return result;
}

fn usz unique_permutation_count(uint8* values, usz length) {
    if (length == 0) return 0;
    usz[128] frequencies = {0};
    for (usz index = 0; index < length; index++) frequencies[values[index]]++;
    usz count = factorial(length);
    for (usz value = 0; value < 128; value++) count /= factorial(frequencies[value]);
    return count;
}

fn bool next_permutation(uint8* values, usz length) {
    if (length < 2) return false;
    usz pivot = length - 1;
    while (pivot > 0 && values[pivot - 1] >= values[pivot]) pivot--;
    if (pivot == 0) return false;
    usz successor = length - 1;
    while (values[successor] <= values[pivot - 1]) successor--;
    uint8 temporary = values[pivot - 1];
    values[pivot - 1] = values[successor];
    values[successor] = temporary;
    usz left = pivot, right = length - 1;
    while (left < right) {
        temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
        left++;
        right--;
    }
    return true;
}

fn long permute_string(long* input, usz input_length, char* output, usz output_capacity)
    @export("permute_string") {
    if (input == null || input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_N) return -1;
    usz character_count = (usz)input[0];
    if (input_length != character_count + 1) return -1;

    uint8[MAX_N] values = {0};
    for (usz index = 0; index < character_count; index++) {
        long value = input[index + 1];
        if (value < 0 || value > 127) return -1;
        values[index] = (uint8)value;
    }
    for (usz index = 1; index < character_count; index++) {
        uint8 value = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            position--;
        }
        values[position] = value;
    }

    usz permutation_count = unique_permutation_count(&values[0], character_count);
    usz output_bytes = permutation_count * character_count;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz row = 0; row < permutation_count; row++) {
        for (usz column = 0; column < character_count; column++)
            output[row * character_count + column] = (char)values[column];
        if (row + 1 < permutation_count) (void)next_permutation(&values[0], character_count);
    }
    return (long)output_bytes;
}
