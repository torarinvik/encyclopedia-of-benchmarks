module minimum_coin_change_greedy;

const long MIN_TARGET = -4096;
const long MAX_TARGET = 4096;
const long MAX_DENOMINATIONS = 32;
const long MAX_INPUT_VALUES = 34;
const long MAX_OUTPUT_BYTES = 16388;

fn void write_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits = bits >> 8;
    }
}

fn long minimum_coin_change_greedy(long* input, usz length, char* output, usz capacity)
    @export("minimum_coin_change_greedy") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long target = input[0];
    long count_value = input[1];
    if (target < MIN_TARGET || target > MAX_TARGET || count_value < 0 || count_value > MAX_DENOMINATIONS)
        return -1;
    usz denomination_count = (usz)count_value;
    if (length != 2 + denomination_count) return -1;

    int denominations[32] = {0};
    long previous = 0;
    for (usz index = 0; index < denomination_count; index++) {
        long denomination = input[2 + index];
        if (denomination < 1 || denomination > 4096 || denomination <= previous) return -1;
        denominations[index] = (int)denomination;
        previous = denomination;
    }

    int chosen[4096] = {0};
    usz chosen_count = 0;
    if (target > 0) {
        long remaining = target;
        usz index = denomination_count;
        while (index > 0) {
            index--;
            int denomination = denominations[index];
            while (remaining >= denomination) {
                remaining -= denomination;
                chosen[chosen_count] = denomination;
                chosen_count++;
            }
        }
    }

    usz needed = (1 + chosen_count) * 4;
    if (output == null || capacity < needed) return -2;
    write_i32_le(output, 0, (int)chosen_count);
    for (usz index = 0; index < chosen_count; index++)
        write_i32_le(output, 4 + 4 * index, chosen[index]);
    return (long)needed;
}
