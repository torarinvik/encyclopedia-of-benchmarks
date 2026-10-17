module link_list_sort;

fn long link_list_sort(long* input, usz length, uint8* output, usz output_capacity) @export("link_list_sort") {
    if (input == null || length < 2 || length > 130) { return -1; }
    long selector = input[0], count_value = input[1];
    if (selector < 1 || selector > 3 || count_value < 0 || count_value > 128) { return -1; }
    usz count = (usz)count_value;
    if (length != 2 + count) { return -1; }

    int[128] items = {0}, scratch = {0};
    for (usz i = 0; i < count; i++) {
        if (input[2 + i] < -2147483648 || input[2 + i] > 2147483647) { return -1; }
        items[i] = (int)input[2 + i];
    }
    if (selector == 1) {
        usz width = 1;
        while (width < count) {
            usz start = 0;
            while (start < count) {
                usz middle = start + width;
                if (middle > count) { middle = count; }
                usz end = middle + width;
                if (end > count) { end = count; }
                usz left = start, right = middle, out = start;
                while (left < middle && right < end) {
                    if (items[left] <= items[right]) { scratch[out++] = items[left++]; }
                    else { scratch[out++] = items[right++]; }
                }
                while (left < middle) { scratch[out++] = items[left++]; }
                while (right < end) { scratch[out++] = items[right++]; }
                start = end;
            }
            for (usz i = 0; i < count; i++) { items[i] = scratch[i]; }
            width *= 2;
        }
    } else if (selector == 2) {
        for (usz i = 1; i < count; i++) {
            int value = items[i];
            usz j = i;
            while (j > 0 && items[j - 1] > value) { items[j] = items[j - 1]; j--; }
            items[j] = value;
        }
    } else {
        usz start = count / 2;
        while (start > 0) {
            start--;
            usz root = start;
            while (root < count / 2) {
                usz child = 2 * root + 1;
                if (child + 1 < count && items[child + 1] > items[child]) { child++; }
                if (items[root] >= items[child]) { break; }
                int value = items[root]; items[root] = items[child]; items[child] = value;
                root = child;
            }
        }
        usz end = count;
        while (end > 1) {
            end--;
            int value = items[0]; items[0] = items[end]; items[end] = value;
            usz root = 0;
            while (root < end / 2) {
                usz child = 2 * root + 1;
                if (child + 1 < end && items[child + 1] > items[child]) { child++; }
                if (items[root] >= items[child]) { break; }
                value = items[root]; items[root] = items[child]; items[child] = value;
                root = child;
            }
        }
    }

    usz required = 4 * count;
    if (output == null || output_capacity < required) { return -2; }
    for (usz i = 0; i < count; i++) {
        uint32 bits = (uint32)items[i];
        for (usz byte = 0; byte < 4; byte++) { output[4 * i + byte] = (uint8)(bits >> (8 * byte)); }
    }
    return (long)required;
}
