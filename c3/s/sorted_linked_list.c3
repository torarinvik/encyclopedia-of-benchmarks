module sorted_linked_list;

const usz MAX_INITIAL_COUNT = 16;
const usz MAX_INPUT_LENGTH = 20;
const usz MAX_OUTPUT_WORDS = 18;

struct ListNode { int value; int next; }

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long sorted_linked_list(long* input, usz input_length, char* output, usz capacity)
        @export("sorted_linked_list") {
    if (input == null || input_length < 3 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_INITIAL_COUNT) return -1;
    usz count = (usz)input[0];
    if (input_length != count + 3) return -1;

    ListNode[17] nodes;
    for (usz index = 0; index < count; index += 1) {
        long value = input[index + 1];
        if (value < -2147483648 || value > 2147483647 || (index > 0 && input[index] >= value)) return -1;
        nodes[index].value = (int)value;
        nodes[index].next = if (index + 1 < count) (int)(index + 1) else -1;
    }
    long operation_value = input[count + 1];
    long key_value = input[count + 2];
    if (operation_value < 0 || operation_value > 2 || key_value < -2147483648 || key_value > 2147483647) return -1;
    int operation = (int)operation_value;
    int key = (int)key_value;
    int head = if (count == 0) -1 else 0;
    int tail = if (count == 0) -1 else (int)(count - 1);

    if (operation == 0) {
        int current = head;
        while (current >= 0) {
            if (nodes[(usz)current].value == key) return -1;
            current = nodes[(usz)current].next;
        }
    }

    long[MAX_OUTPUT_WORDS] staged;
    usz word_count = 0;
    if (operation == 0) {
        int new_node = (int)count;
        nodes[(usz)new_node].value = key;
        nodes[(usz)new_node].next = -1;
        if (head < 0) { head = new_node; tail = new_node; }
        else if (key < nodes[(usz)head].value) { nodes[(usz)new_node].next = head; head = new_node; }
        else if (key > nodes[(usz)tail].value) { nodes[(usz)tail].next = new_node; tail = new_node; }
        else {
            int previous = head;
            while (nodes[(usz)previous].next >= 0 && nodes[(usz)nodes[(usz)previous].next].value < key)
                previous = nodes[(usz)previous].next;
            nodes[(usz)new_node].next = nodes[(usz)previous].next;
            nodes[(usz)previous].next = new_node;
            if (nodes[(usz)new_node].next < 0) tail = new_node;
        }
        staged[word_count++] = (long)(count + 1);
        for (int node = head; node >= 0; node = nodes[(usz)node].next) staged[word_count++] = nodes[(usz)node].value;
    } else if (operation == 1) {
        int found = 0;
        for (int node = head; node >= 0; node = nodes[(usz)node].next) {
            if (nodes[(usz)node].value == key) { found = 1; break; }
        }
        staged[word_count++] = found;
    } else {
        int deleted = 0;
        if (head >= 0 && nodes[(usz)head].value == key) {
            head = nodes[(usz)head].next;
            if (head < 0) tail = -1;
            deleted = 1;
        } else {
            int previous = head;
            while (previous >= 0 && nodes[(usz)previous].next >= 0) {
                int candidate = nodes[(usz)previous].next;
                if (nodes[(usz)candidate].value == key) {
                    nodes[(usz)previous].next = nodes[(usz)candidate].next;
                    if (tail == candidate) tail = previous;
                    deleted = 1;
                    break;
                }
                previous = candidate;
            }
        }
        staged[word_count++] = deleted;
        usz remaining = 0;
        for (int node = head; node >= 0; node = nodes[(usz)node].next) remaining += 1;
        staged[word_count++] = (long)remaining;
        for (int node = head; node >= 0; node = nodes[(usz)node].next) staged[word_count++] = nodes[(usz)node].value;
    }
    usz output_bytes = word_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < word_count; index += 1) put_i64_le(output, index * 8, staged[index]);
    return (long)output_bytes;
}
