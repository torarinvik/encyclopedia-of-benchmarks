module subset_combinations;

// Emit fixed-size index combinations as little-endian subset masks.
fn long subset_combinations(long* input, usz length, char* output, usz output_capacity) @export("subset_combinations")
{
    if (length == 0 || length > 13 || input[0] < 0) return -1;
    usz item_count = length - 1;
    if (item_count > 12) return -1;
    if (input[0] > (long)item_count) return 0;
    usz choose = (usz)input[0];
    usz count = 1;
    for (usz index = 1; index <= choose; index++) count = count * (item_count - choose + index) / index;
    usz required = 2 * count;
    if (output_capacity < required || (required != 0 && output == null)) return -2;
    usz[12] indices;
    for (usz index = 0; index < choose; index++) indices[index] = index;
    for (usz combination = 0; combination < count; combination++) {
        usz mask = 0;
        for (usz index = 0; index < choose; index++) mask |= (usz)1 << indices[index];
        output[2 * combination] = (char)(mask & 255);
        output[2 * combination + 1] = (char)(mask >> 8);
        if (combination + 1 == count) break;
        usz position = choose;
        while (position > 0) {
            position--;
            if (indices[position] < item_count - choose + position) break;
        }
        indices[position]++;
        for (usz index = position + 1; index < choose; index++) indices[index] = indices[index - 1] + 1;
    }
    return (long)count;
}
