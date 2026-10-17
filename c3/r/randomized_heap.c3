module randomized_heap;

const usz MAX_OPS = 64;
const usz MAX_INPUT_LENGTH = 129;
const usz MAX_OUTPUT_WORDS = 1 + 2 * MAX_OPS;
const usz MAX_OUTPUT_BYTES = 4 * MAX_OUTPUT_WORDS;

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long randomized_heap(long* input, usz length, char* output, usz capacity)
        @export("randomized_heap") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 64) return -1;
    usz operation_count = (usz)input[0];
    int[64] heap = zeroed;
    int[129] words;
    usz heap_size = 0, word_count = 1, query_count = 0, pos = 1;

    for (usz op = 0; op < operation_count; op += 1) {
        if (pos >= length) return -1;
        long opcode = input[pos++];
        if (opcode == 0) {
            if (pos >= length) return -1;
            long raw = input[pos++];
            if (raw < -2147483648 || raw > 2147483647) return -1;
            usz index = heap_size;
            heap[index] = (int)raw;
            while (index > 0) {
                usz parent = (index - 1) / 2;
                if (heap[parent] <= heap[index]) break;
                int tmp = heap[parent];
                heap[parent] = heap[index];
                heap[index] = tmp;
                index = parent;
            }
            heap_size += 1;
        } else if (opcode == 1 || opcode == 2) {
            if (heap_size == 0) return -1;
            int value = heap[0];
            if (opcode == 2) {
                heap_size -= 1;
                if (heap_size > 0) {
                    heap[0] = heap[heap_size];
                    usz index = 0;
                    while (true) {
                        usz left = 2 * index + 1;
                        if (left >= heap_size) break;
                        usz right = left + 1, child = left;
                        if (right < heap_size && heap[right] < heap[left]) child = right;
                        if (heap[index] <= heap[child]) break;
                        int tmp = heap[index];
                        heap[index] = heap[child];
                        heap[child] = tmp;
                        index = child;
                    }
                }
            }
            words[word_count++] = (int)opcode;
            words[word_count++] = value;
            query_count += 1;
        } else if (opcode == 3) {
            words[word_count++] = 3;
            words[word_count++] = (int)(heap_size == 0);
            query_count += 1;
        } else return -1;
    }

    if (pos != length || word_count > MAX_OUTPUT_WORDS) return -1;
    words[0] = (int)query_count;
    usz bytes = word_count * 4;
    if (output == null || capacity < bytes) return -2;
    char[516] buffer;
    for (usz i = 0; i < word_count; i += 1) put_i32_le(&buffer[0], i * 4, words[i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
