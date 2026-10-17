module list_based_queue;

long list_based_queue(long* input, usz length, char* output, usz output_capacity)
        @export("list_based_queue") {
    if (input == null || length < 1 || length > 66 || input[0] < 0 || input[0] > 32) return -1;
    usz op_count = (usz)input[0];
    long node_values[32], next_node[32], words[64];
    usz allocated = 0, word_count = 0, pos = 1, size = 0;
    long head = -1, tail = -1;
    for (usz i = 0; i < op_count; i++) {
        if (pos >= length) return -1;
        long opcode = input[pos++];
        if (opcode == 0) {
            if (pos >= length) return -1;
            long value = input[pos++];
            if (value < -2147483648L || value > 2147483647L || allocated >= 32) return -1;
            node_values[allocated] = value;
            next_node[allocated] = -1;
            if (tail < 0) head = (long)allocated;
            else next_node[(usz)tail] = (long)allocated;
            tail = (long)allocated;
            allocated++; size++;
            words[word_count++] = 0; words[word_count++] = 1;
        } else if (opcode == 1) {
            if (head < 0) return -1;
            long node = head;
            head = next_node[(usz)node];
            if (head < 0) tail = -1;
            size--;
            words[word_count++] = 1; words[word_count++] = node_values[(usz)node];
        } else if (opcode == 2) {
            if (head < 0) return -1;
            words[word_count++] = 2; words[word_count++] = node_values[(usz)head];
        } else if (opcode == 3) {
            head = -1; tail = -1; size = 0;
            words[word_count++] = 3; words[word_count++] = 1;
        } else if (opcode == 4) {
            words[word_count++] = 4; words[word_count++] = size == 0 ? 1 : 0;
        } else if (opcode == 5) {
            words[word_count++] = 5; words[word_count++] = 0;
        } else return -1;
    }
    if (pos != length || length > 1 + 2 * op_count || word_count > 64) return -1;
    usz bytes = word_count * 8;
    if (output == null || output_capacity < bytes) return -2;
    for (usz i = 0; i < word_count; i++) {
        ulong bits = (ulong)words[i];
        for (usz b = 0; b < 8; b++) output[8 * i + b] = (char)((bits >> (8 * b)) & 255);
    }
    return (long)bytes;
}
