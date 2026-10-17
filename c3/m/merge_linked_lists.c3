module merge_linked_lists;

const usz MAX_LIST_LENGTH = 32;
const usz MAX_TOTAL_NODES = 2 * MAX_LIST_LENGTH;
const usz MAX_PARSEABLE_INPUT_LENGTH = 2 + MAX_TOTAL_NODES + 1;

fn void store_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long merge_linked_lists(long* values, usz length, char* output,
                           usz output_capacity) @export("merge_linked_lists") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long raw_first = values[0];
    long raw_second = values[1];
    if (raw_first < 0 || raw_first > 32 || raw_second < 0 || raw_second > 32) return -1;
    usz first_length = (usz)raw_first;
    usz second_length = (usz)raw_second;
    usz total = first_length + second_length;
    if (total > MAX_TOTAL_NODES || length != 2 + total) return -1;

    int[MAX_TOTAL_NODES] node_values = {0};
    int[MAX_TOTAL_NODES] next = {0};
    for (usz index = 0; index < first_length; index++) {
        long value = values[2 + index];
        if (value < -2147483648L || value > 2147483647L) return -1;
        node_values[index] = (int)value;
        next[index] = index + 1 < first_length ? (int)(index + 1) : -1;
    }
    usz second_start = first_length;
    for (usz index = 0; index < second_length; index++) {
        long value = values[2 + first_length + index];
        if (value < -2147483648L || value > 2147483647L) return -1;
        usz node = second_start + index;
        node_values[node] = (int)value;
        next[node] = index + 1 < second_length ? (int)(node + 1) : -1;
    }

    int head1 = first_length == 0 ? -1 : 0;
    int head2 = second_length == 0 ? -1 : (int)second_start;
    int temp1 = head1;
    int temp2 = head2;
    int holder2 = -1;
    while (temp1 != -1 && temp2 != -1) {
        int holder1 = next[temp1];
        next[temp1] = temp2;
        if (holder1 != -1) {
            holder2 = next[temp2];
            next[temp2] = holder1;
        }
        temp1 = holder1;
        temp2 = holder2;
    }

    usz output_count = 0;
    int node = head1;
    while (node != -1) {
        if (node < 0 || (usz)node >= total || output_count >= total) return -1;
        output_count++;
        node = next[node];
    }
    usz required = output_count * 8;
    if (output == null || output_capacity < required) return -2;

    node = head1;
    for (usz index = 0; index < output_count; index++) {
        store_i64_le((long)node_values[node], output, 8 * index);
        node = next[node];
    }
    return (long)required;
}
