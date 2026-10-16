module triplet_sum_two_pointer;

const MAX_ITEMS = 1024;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn void sift_down(long* values, usz root_value, usz end) {
    usz root = root_value;
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        long temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}

fn void heap_sort(long* values, usz length) {
    for (usz start = length / 2; start > 0; start--) sift_down(values, start - 1, length);
    for (usz end = length; end > 1; end--) {
        long temporary = values[0]; values[0] = values[end - 1]; values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}

fn long triplet_sum_two_pointer(long* input, usz length, char* output, usz output_capacity)
    @export("triplet_sum_two_pointer") {
    if (input == null || length < 1 || length > MAX_ITEMS + 1 ||
        input[0] < -3000000 || input[0] > 3000000) return -1;
    usz item_count = length - 1;
    long[MAX_ITEMS] values;
    for (usz index = 0; index < item_count; index++) {
        if (input[index + 1] < -1000000 || input[index + 1] > 1000000) return -1;
        values[index] = input[index + 1];
    }
    if (output_capacity < 24 || output == null) return -2;
    heap_sort(&values, item_count);
    long[3] result;
    result[0] = 0; result[1] = 0; result[2] = 0;
    for (usz first = 0; first + 2 < item_count; first++) {
        usz left = first + 1;
        usz right = item_count - 1;
        while (left < right) {
            long sum = values[first] + values[left] + values[right];
            if (sum == input[0]) {
                result[0] = values[first]; result[1] = values[left]; result[2] = values[right];
                first = item_count;
                break;
            }
            if (sum < input[0]) { left++; }
            else { right--; }
        }
        if (first == item_count) break;
    }
    for (usz index = 0; index < 3; index++) put_i64_le(output, index * 8, result[index]);
    return 3;
}
