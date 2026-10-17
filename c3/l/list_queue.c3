module list_queue;

const usz MAX_QUEUE_SIZE = 10;
const usz MAX_OPS = 64;
const usz MAX_INPUT_LENGTH = 129;
const usz MAX_OUTPUT_WORDS = 130;
const usz MAX_OUTPUT_BYTES = 520;

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long list_queue(long* input, usz length, char* output, usz capacity)
        @export("list_queue") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 64) return -1;
    usz op_count = (usz)input[0];
    int[10] queue = zeroed;
    int[130] words;
    usz word_count = 1, query_count = 0, pos = 1, queue_size = 0;
    for (usz op = 0; op < op_count; op += 1) {
        if (pos >= length) return -1;
        long opcode = input[pos++];
        if (opcode == 0) {
            if (pos >= length) return -1;
            long raw = input[pos++];
            if (raw < -2147483648 || raw > 2147483647 || queue_size >= MAX_QUEUE_SIZE) return -1;
            queue[queue_size++] = (int)raw;
        } else if (opcode == 1) {
            if (queue_size == 0) {
                words[word_count++] = 3;
                words[word_count++] = 0;
            } else {
                int value = queue[0];
                for (usz i = 0; i + 1 < MAX_QUEUE_SIZE; i += 1) queue[i] = queue[i + 1];
                queue_size -= 1;
                words[word_count++] = 1;
                words[word_count++] = value;
            }
            query_count += 1;
        } else if (opcode == 2) {
            words[word_count++] = 2;
            words[word_count++] = (int)queue_size;
            query_count += 1;
        } else return -1;
    }
    if (pos != length || word_count + 1 + queue_size > MAX_OUTPUT_WORDS) return -1;
    words[0] = (int)query_count;
    words[word_count++] = (int)queue_size;
    for (usz i = 0; i < queue_size; i += 1) words[word_count++] = queue[i];
    usz bytes = word_count * 4;
    if (output == null || capacity < bytes) return -2;
    char[520] buffer;
    for (usz i = 0; i < word_count; i += 1) put_i32_le(&buffer[0], i * 4, words[i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
