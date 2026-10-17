module sort_population;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long sort_population(long* input, usz length, char* output, usz capacity)
    @export("sort_population") {
    if (input == null || length < 3 || length > 129 || input[0] < 1 || input[0] > 64) return -1;
    usz count = (usz)input[0];
    if (length != 1 + 2 * count) return -1;
    long costs[64], identifiers[64];
    bool seen[64];
    for (usz index = 0; index < 64; index++) seen[index] = false;
    for (usz index = 0; index < count; index++) {
        long cost = input[1 + 2 * index], identifier = input[2 + 2 * index];
        if (cost < -1000000 || cost > 1000000 || identifier < 0 || identifier >= (long)count) return -1;
        if (seen[(usz)identifier]) return -1;
        seen[(usz)identifier] = true;
        costs[index] = cost;
        identifiers[index] = identifier;
    }
    for (usz index = 1; index < count; index++) {
        long key_cost = costs[index], key_identifier = identifiers[index];
        usz position = index;
        while (position > 0 && costs[position - 1] > key_cost) {
            costs[position] = costs[position - 1];
            identifiers[position] = identifiers[position - 1];
            position--;
        }
        costs[position] = key_cost;
        identifiers[position] = key_identifier;
    }
    for (usz index = 1; index < count; index++) if (costs[index - 1] == costs[index]) return -1;
    usz output_length = count * 16;
    if (output == null || capacity < output_length) return -2;
    for (usz index = 0; index < count; index++) {
        write_i64_le(output, index * 16, costs[index]);
        write_i64_le(output, index * 16 + 8, identifiers[index]);
    }
    return (long)output_length;
}
