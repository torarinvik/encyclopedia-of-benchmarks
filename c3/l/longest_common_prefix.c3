module longest_common_prefix;

fn int compare_strings(long* input, usz start_a, usz len_a, usz start_b, usz len_b) {
    usz limit = len_a < len_b ? len_a : len_b;
    for (usz i = 0; i < limit; i++) {
        if (input[start_a + i] < input[start_b + i]) return -1;
        if (input[start_a + i] > input[start_b + i]) return 1;
    }
    return len_a < len_b ? -1 : len_a > len_b ? 1 : 0;
}

fn long longest_common_prefix(long* input, usz length, char* output, usz capacity) @export("longest_common_prefix") {
    if (input == null || length < 1 || length > 1041 || input[0] < 0 || input[0] > 16) return -1;
    usz count = (usz)input[0];
    usz[16] starts; usz[16] sizes; usz position = 1;
    for (usz i = 0; i < count; i++) {
        if (position >= length || input[position] < 0 || input[position] > 64) return -1;
        sizes[i] = (usz)input[position++];
        if (sizes[i] > length - position) return -1;
        starts[i] = position;
        for (usz j = 0; j < sizes[i]; j++) if (input[position + j] < 0 || input[position + j] > 127) return -1;
        position += sizes[i];
    }
    if (position != length) return -1;
    if (count == 0) return 0;
    usz[16] order;
    for (usz i = 0; i < count; i++) order[i] = i;
    for (usz i = 1; i < count; i++) {
        usz value = order[i]; usz j = i;
        while (j > 0 && compare_strings(input, starts[order[j - 1]], sizes[order[j - 1]], starts[value], sizes[value]) > 0) {
            order[j] = order[j - 1]; j--;
        }
        order[j] = value;
    }
    usz first = order[0], last = order[count - 1];
    usz limit = sizes[first] < sizes[last] ? sizes[first] : sizes[last];
    usz prefix = 0;
    while (prefix < limit && input[starts[first] + prefix] == input[starts[last] + prefix]) prefix++;
    if (capacity < prefix || (prefix != 0 && output == null)) return -2;
    for (usz i = 0; i < prefix; i++) output[i] = (char)input[starts[first] + i];
    return (long)prefix;
}
