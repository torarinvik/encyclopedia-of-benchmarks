module merge_two_binary_trees;

const usz MAX_TREE_SLOTS = 255;
const usz MAX_INPUT_LENGTH = 512;
const long NULL_SLOT = -1000001;

fn bool valid_tree(long* input, usz start, usz count) {
    for (usz index = 0; index < count; index++) {
        long value = input[start + index];
        if (value != NULL_SLOT && (value < -100000 || value > 100000)) return false;
        if (index > 0 && input[start + (index - 1) / 2] == NULL_SLOT && value != NULL_SLOT) return false;
    }
    return true;
}

fn long merge_two_binary_trees(long* input, usz length, char* output, usz output_capacity)
        @export("merge_two_binary_trees") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_TREE_SLOTS) return -1;
    usz first_count = (usz)input[0];
    usz second_count_position = first_count + 1;
    if (second_count_position >= length) return -1;
    if (input[second_count_position] < 0 || input[second_count_position] > (long)MAX_TREE_SLOTS) return -1;
    usz second_count = (usz)input[second_count_position];
    usz first_start = 1;
    usz second_start = second_count_position + 1;
    if (length != second_start + second_count) return -1;
    if (!valid_tree(input, first_start, first_count) || !valid_tree(input, second_start, second_count)) return -1;

    usz maximum_slots = first_count > second_count ? first_count : second_count;
    int[MAX_TREE_SLOTS] merged;
    long node_count = 0;
    for (usz index = 0; index < maximum_slots; index++) {
        long first = index < first_count ? input[first_start + index] : NULL_SLOT;
        long second = index < second_count ? input[second_start + index] : NULL_SLOT;
        if (first == NULL_SLOT && second == NULL_SLOT) {
            merged[index] = -1000001;
        } else {
            long value = (first == NULL_SLOT ? 0 : first) + (second == NULL_SLOT ? 0 : second);
            merged[index] = (int)value;
            node_count++;
        }
    }
    usz output_slots = maximum_slots;
    while (output_slots > 0 && merged[output_slots - 1] == -1000001) output_slots--;
    usz output_bytes = output_slots * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) return -2;
    for (usz index = 0; index < output_slots; index++) {
        uint bits = (uint)merged[index];
        for (usz byte = 0; byte < 4; byte++) output[index * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
    return node_count;
}
