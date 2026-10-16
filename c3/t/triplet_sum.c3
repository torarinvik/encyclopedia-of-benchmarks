module triplet_sum;

const MAX_ITEMS = 10;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits >> (8 * byte));
    }
}

fn void sort_three(long* first, long* second, long* third) {
    if (*first > *second) { long value = *first; *first = *second; *second = value; }
    if (*second > *third) { long value = *second; *second = *third; *third = value; }
    if (*first > *second) { long value = *first; *first = *second; *second = value; }
}

fn long triplet_sum(long* input, usz length, char* output, usz output_capacity)
    @export("triplet_sum") {
    if (input == null || length < 1 || length > MAX_ITEMS + 1 ||
        input[0] < -3000000 || input[0] > 3000000) return -1;
    usz item_count = length - 1;
    for (usz index = 0; index < item_count; index++) {
        if (input[index + 1] < -1000000 || input[index + 1] > 1000000) return -1;
    }
    if (output_capacity < 24 || output == null) return -2;

    long[3] result;
    result[0] = 0; result[1] = 0; result[2] = 0;
    bool found = false;
    for (usz first = 0; first < item_count && !found; first++) {
        for (usz second = 0; second < item_count && !found; second++) {
            if (second == first) continue;
            for (usz third = 0; third < item_count; third++) {
                if (third == first || third == second) continue;
                if (input[first + 1] + input[second + 1] + input[third + 1] == input[0]) {
                    result[0] = input[first + 1]; result[1] = input[second + 1]; result[2] = input[third + 1];
                    sort_three(&result[0], &result[1], &result[2]);
                    found = true;
                    break;
                }
            }
        }
    }
    for (usz index = 0; index < 3; index++) put_i64_le(output, index * 8, result[index]);
    return 3;
}
