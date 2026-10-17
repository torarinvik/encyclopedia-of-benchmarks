module merge_sort_linked_list;

fn int merge_nodes(int* values, int* links, int left, int right) {
    if (left < 0) { return right; }
    if (right < 0) { return left; }
    if (values[(usz)left] <= values[(usz)right]) {
        links[(usz)left] = merge_nodes(values, links, links[(usz)left], right);
        return left;
    }
    links[(usz)right] = merge_nodes(values, links, left, links[(usz)right]);
    return right;
}

fn int merge_sort_nodes(int* values, int* links, int head) {
    if (head < 0 || links[(usz)head] < 0) { return head; }
    int slow = head, fast = links[(usz)head];
    while (fast >= 0 && links[(usz)fast] >= 0) {
        slow = links[(usz)slow];
        fast = links[(usz)links[(usz)fast]];
    }
    int right_head = links[(usz)slow];
    links[(usz)slow] = -1;
    int left = merge_sort_nodes(values, links, head);
    int right = merge_sort_nodes(values, links, right_head);
    return merge_nodes(values, links, left, right);
}

fn void put_i32_le(uint8* output, usz offset, int value) {
    uint32 bits = (uint32)value;
    for (usz byte = 0; byte < 4; byte++) { output[offset + byte] = (uint8)(bits >> (8 * byte)); }
}

fn long merge_sort_linked_list(long* input, usz length, uint8* output, usz output_capacity) @export("merge_sort_linked_list") {
    if (input == null || length < 1 || length > 129) { return -1; }
    long count_value = input[0];
    if (count_value < 0 || count_value > 128) { return -1; }
    usz count = (usz)count_value;
    if (length != 1 + count) { return -1; }

    int[128] values = {0}, links = {0};
    for (usz i = 0; i < count; i++) {
        if (input[1 + i] < -2147483648 || input[1 + i] > 2147483647) { return -1; }
        values[i] = (int)input[1 + i];
        for (usz j = 0; j < i; j++) { if (values[j] == values[i]) { return -1; } }
        links[i] = -1;
        if (i + 1 < count) { links[i] = (int)(i + 1); }
    }
    int head = -1;
    if (count > 0) { head = merge_sort_nodes(&values[0], &links[0], 0); }
    usz required = 4 * count;
    if (output == null || output_capacity < required) { return -2; }
    int node = head;
    for (usz i = 0; i < count; i++) {
        put_i32_le(output, i * 4, values[(usz)node]);
        node = links[(usz)node];
    }
    return (long)required;
}
