module selectionsortlinkedlist;

const usz MAX_COUNT = 64;
const usz MAX_INPUT_LENGTH = 66;

fn void selection_sort_links(int* values, int* next, int* head) {
    int minimum = head[0];
    int current = next[minimum];
    int previous = minimum;
    int sorted_tail = -1;
    while (next[minimum] != -1) {
        while (current != -1) {
            if (values[current] < values[minimum]) {
                if (sorted_tail == -1) {
                    if (previous == minimum) {
                        head[0] = current;
                        next[minimum] = next[current];
                        next[current] = previous;
                        minimum = current;
                        current = next[previous];
                    } else {
                        head[0] = current;
                        next[previous] = next[current];
                        next[current] = minimum;
                        minimum = current;
                        current = next[previous];
                    }
                } else {
                    next[sorted_tail] = current;
                    next[previous] = next[current];
                    next[current] = minimum;
                    minimum = current;
                    current = next[previous];
                }
            } else {
                previous = next[previous];
                current = next[current];
            }
        }
        sorted_tail = minimum;
        minimum = next[minimum];
        previous = minimum;
        current = next[minimum];
    }
}

fn void write_i32_le(char* output, usz offset, int value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long selectionsortlinkedlist(long* input, usz length, char* output,
                                usz output_capacity) @export("selectionsortlinkedlist") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long raw_count = input[0];
    if (raw_count < 1 || raw_count > 64 || length != 1 + (usz)raw_count) return -1;
    usz count = (usz)raw_count;
    int[MAX_COUNT] values = {0};
    int[MAX_COUNT] next = {-1};
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) return -1;
        values[index] = (int)value;
        next[index] = index + 1 < count ? (int)(index + 1) : -1;
    }
    usz byte_count = 4 * count;
    if (output == null || output_capacity < byte_count) return -2;

    int head = 0;
    selection_sort_links(&values[0], &next[0], &head);
    int node = head;
    for (usz index = 0; index < count; index++) {
        write_i32_le(output, 4 * index, values[node]);
        node = next[node];
    }
    return (long)byte_count;
}
