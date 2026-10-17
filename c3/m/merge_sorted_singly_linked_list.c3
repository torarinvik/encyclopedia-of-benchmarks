module merge_sorted_singly_linked_list;

const usz MAX_NODES = 128;
const usz MAX_INPUT_LENGTH = 130;
const usz MAX_OUTPUT_BYTES = 1536;

struct ListNode { int value; int next; int origin; int position; }

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long merge_sorted_singly_linked_list(long* input, usz length, char* output, usz capacity)
        @export("merge_sorted_singly_linked_list") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 128) return -1;
    usz len_a = (usz)input[0];
    if (len_a > length - 2) return -1;
    usz len_b_pos = 1 + len_a;
    long raw_len_b = input[len_b_pos];
    if (raw_len_b < 0 || raw_len_b > (long)(MAX_NODES - len_a)) return -1;
    usz len_b = (usz)raw_len_b;
    usz total = len_a + len_b;
    if (length != 2 + total) return -1;

    ListNode[128] nodes;
    for (usz i = 0; i < len_a; i += 1) {
        long raw = input[1 + i];
        if (raw < -2147483648 || raw > 2147483647 || (i > 0 && input[i] > raw)) return -1;
        nodes[i].value = (int)raw;
        nodes[i].next = if (i + 1 < len_a) (int)(i + 1) else -1;
        nodes[i].origin = 0;
        nodes[i].position = (int)i;
    }
    usz b_start = len_b_pos + 1;
    for (usz i = 0; i < len_b; i += 1) {
        long raw = input[b_start + i];
        if (raw < -2147483648 || raw > 2147483647 || (i > 0 && input[b_start + i - 1] > raw)) return -1;
        usz node = len_a + i;
        nodes[node].value = (int)raw;
        nodes[node].next = if (i + 1 < len_b) (int)(node + 1) else -1;
        nodes[node].origin = 1;
        nodes[node].position = (int)i;
    }

    int head_a = if (len_a == 0) -1 else 0;
    int head_b = if (len_b == 0) -1 else (int)len_a;
    int merged_head = -1, tail = -1;
    while (head_a >= 0 && head_b >= 0) {
        int node;
        if (nodes[(usz)head_a].value <= nodes[(usz)head_b].value) {
            node = head_a;
            head_a = nodes[(usz)node].next;
        } else {
            node = head_b;
            head_b = nodes[(usz)node].next;
        }
        if (tail < 0) merged_head = node;
        else nodes[(usz)tail].next = node;
        tail = node;
    }
    int remainder = if (head_a >= 0) head_a else head_b;
    if (tail < 0) merged_head = remainder;
    else nodes[(usz)tail].next = remainder;

    usz bytes = 12 * total;
    if (output == null || capacity < bytes) return -2;
    char[1536] buffer;
    usz written = 0;
    int node = merged_head;
    while (node >= 0) {
        put_i32_le(&buffer[0], written, nodes[(usz)node].value);
        put_i32_le(&buffer[0], written + 4, nodes[(usz)node].origin);
        put_i32_le(&buffer[0], written + 8, nodes[(usz)node].position);
        written += 12;
        node = nodes[(usz)node].next;
    }
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
