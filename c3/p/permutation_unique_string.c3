module permutation_unique_string;

const usz MAX_LENGTH = 5;
const usz MAX_INPUT = 7;
const usz MAX_OUTPUT = 601;

fn long permutation_unique_string(long* input, usz input_length, char* output, usz capacity)
    @export("permutation_unique_string") {
    if (input == null || input_length == 0 || input_length > MAX_INPUT) return -1L;
    if (input[0] < 0 || input[0] > 5 || input_length != (usz)input[0] + 1) return -1L;
    usz length = (usz)input[0];
    uint8[MAX_LENGTH] current = zeroed;
    for (usz i = 0; i < length; i++) {
        if (input[i + 1] < 32 || input[i + 1] > 126) return -1L;
        current[i] = (uint8)input[i + 1];
    }
    for (usz i = 1; i < length; i++) {
        uint8 value = current[i];
        usz j = i;
        while (j > 0 && current[j - 1] > value) { current[j] = current[j - 1]; j--; }
        current[j] = value;
    }
    uint8[MAX_OUTPUT] staged = zeroed;
    usz count = 0;
    while (true) {
        for (usz i = 0; i < length; i++) staged[1 + count * length + i] = current[i];
        count++;
        if (length < 2) break;
        usz pivot = length - 1;
        while (pivot > 0 && current[pivot - 1] >= current[pivot]) pivot--;
        if (pivot == 0) break;
        usz successor = length - 1;
        while (current[successor] <= current[pivot - 1]) successor--;
        uint8 temp = current[pivot - 1]; current[pivot - 1] = current[successor]; current[successor] = temp;
        usz left = pivot, right = length - 1;
        while (left < right) { temp = current[left]; current[left] = current[right]; current[right] = temp; left++; right--; }
    }
    staged[0] = (uint8)count;
    usz output_size = 1 + count * length;
    if (output == null || capacity < output_size) return -2L;
    for (usz i = 0; i < output_size; i++) output[i] = (char)staged[i];
    return (long)output_size;
}
