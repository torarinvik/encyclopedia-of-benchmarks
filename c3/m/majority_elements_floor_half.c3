module majority_elements_floor_half;

const usz MAX_INPUT_LENGTH = 256;
const usz TABLE_SIZE = 512;

fn long majority_elements_floor_half(long* input, usz length, char* output,
        usz capacity) @export("majority_elements_floor_half") {
    if (length > MAX_INPUT_LENGTH || (length != 0 && input == null)) return -1;

    int[TABLE_SIZE] keys;
    usz[TABLE_SIZE] counts;
    bool[TABLE_SIZE] used;
    usz[MAX_INPUT_LENGTH] insertion_order;
    usz unique_count = 0;

    for (usz index = 0; index < length; index++) {
        if (input[index] < -2147483648 || input[index] > 2147483647) return -1;
        long remainder = input[index] % (long)TABLE_SIZE;
        if (remainder < 0) remainder += (long)TABLE_SIZE;
        usz slot = (usz)remainder;
        int value = (int)input[index];
        while (used[slot] && keys[slot] != value) {
            slot = (slot + 1) & (TABLE_SIZE - 1);
        }
        if (!used[slot]) {
            used[slot] = true;
            keys[slot] = value;
            counts[slot] = 1;
            insertion_order[unique_count++] = slot;
        } else {
            counts[slot]++;
        }
    }

    int[MAX_INPUT_LENGTH] result;
    usz result_count = 0;
    usz threshold = length / 2;
    for (usz index = 0; index < unique_count; index++) {
        usz slot = insertion_order[index];
        if (counts[slot] >= threshold) result[result_count++] = keys[slot];
    }
    for (usz index = 1; index < result_count; index++) {
        int value = result[index];
        usz position = index;
        while (position > 0 && result[position - 1] > value) {
            result[position] = result[position - 1];
            position--;
        }
        result[position] = value;
    }

    usz required = result_count * 4;
    if (capacity < required || (required != 0 && output == null)) return -2;
    usz written = 0;
    for (usz index = 0; index < result_count; index++) {
        uint bits = (uint)result[index];
        for (usz byte = 0; byte < 4; byte++) {
            output[written++] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return (long)result_count;
}
