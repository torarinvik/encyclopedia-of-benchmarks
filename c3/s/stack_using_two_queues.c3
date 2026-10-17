module stack_using_two_queues;

long stack_using_two_queues(long* input, usz length, char* output, usz output_capacity)
        @export("stack_using_two_queues") {
    if (input == null || length < 1 || length > 257 || input[0] < 0 || input[0] > 128 ||
        length != 1 + 2 * (usz)input[0]) return -1;
    long queue_a[128], queue_b[128], tags[128], results[128];
    long* main_queue = queue_a;
    long* temp_queue = queue_b;
    usz head = 0, tail = 0, record_count = 0, position = 1;
    for (usz opi = 0; opi < (usz)input[0]; opi++) {
        long opcode = input[position], operand = input[position + 1];
        position += 2;
        if (opcode == 0) {
            if (operand < -2147483648L || operand > 2147483647L) return -1;
            usz temp_tail = 0;
            temp_queue[temp_tail++] = operand;
            while (head < tail) temp_queue[temp_tail++] = main_queue[head++];
            long* swap = main_queue; main_queue = temp_queue; temp_queue = swap;
            head = 0; tail = temp_tail;
        } else if (opcode == 1) {
            if (operand != 0 || head == tail) return -1;
            tags[record_count] = 0;
            results[record_count++] = main_queue[head++];
        } else if (opcode == 2) {
            if (operand != 0) return -1;
            if (head == tail) { tags[record_count] = 1; results[record_count++] = 0; }
            else { tags[record_count] = 0; results[record_count++] = main_queue[head]; }
        } else return -1;
    }
    usz bytes = record_count * 16;
    if (output == null || output_capacity < bytes) return -2;
    for (usz i = 0; i < record_count; i++) {
        ulong tag_bits = (ulong)tags[i], value_bits = (ulong)results[i];
        for (usz b = 0; b < 8; b++) {
            output[16 * i + b] = (char)((tag_bits >> (8 * b)) & 255);
            output[16 * i + 8 + b] = (char)((value_bits >> (8 * b)) & 255);
        }
    }
    return (long)bytes;
}
