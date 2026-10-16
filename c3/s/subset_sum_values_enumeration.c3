module subset_sum_values_enumeration;

const usz MAX_ITEMS = 11;
const long MAX_TARGET = 256;
const long MAX_ITEM = 64;

fn void write_i64_le(char* output, usz* position, long value) {
    usz shift = 0;
    while (shift < 64) {
        output[*position] = (char)((value >> shift) & 255);
        *position = *position + 1;
        shift = shift + 8;
    }
}

fn usz enumerate(long* items, usz item_count, usz index, long target,
                 long sum, long* chosen, usz chosen_count, char* output,
                 usz* position, bool emit) {
    if (sum == target) {
        if (emit) {
            write_i64_le(output, position, (long)chosen_count);
            for (usz i = 0; i < chosen_count; i++) write_i64_le(output, position, chosen[i]);
        }
        return chosen_count + 1;
    }
    if (index == item_count || sum > target) return 0;
    chosen[chosen_count] = items[index];
    usz include_slots = enumerate(items, item_count, index + 1, target,
        sum + items[index], chosen, chosen_count + 1, output, position, emit);
    usz exclude_slots = enumerate(items, item_count, index + 1, target,
        sum, chosen, chosen_count, output, position, emit);
    return include_slots + exclude_slots;
}

fn long subset_sum_values_enumeration(long* input, usz length, char* output,
                                       usz output_capacity) @export("subset_sum_values_enumeration") {
    if (input == null || length == 0 || length > MAX_ITEMS + 1) return -1;
    long target = input[0];
    if (target < 0 || target > MAX_TARGET) return -1;
    usz items = length - 1;
    for (usz i = 0; i < items; i++) if (input[i + 1] < 1 || input[i + 1] > MAX_ITEM) return -1;

    long[MAX_ITEMS] chosen;
    usz dummy_position = 0;
    usz slots = enumerate(input + 1, items, 0, target, 0, &chosen[0], 0,
                          null, &dummy_position, false);
    usz required = slots * 8;
    if (required == 0) return 0;
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    enumerate(input + 1, items, 0, target, 0, &chosen[0], 0,
              output, &position, true);
    return (long)position;
}
