module element_priority_queue_using_list;

void store_i64(char* output, usz offset, long value) { ulong bits = @bitcast(ulong, value); for (usz i = 0; i < 8; i++) output[offset + i] = (char)(bits >> (8 * i)); }

fn long element_priority_queue_using_list(long* input, usz length, char* output, usz capacity)
    @export("element_priority_queue_using_list") {
    if (input == null || length < 1 || length > 514) return -1;
    long operation_count = input[0];
    if (operation_count < 0 || operation_count > 256 || length != 1 + 2 * (usz)operation_count) return -1;
    int[100] queue = zeroed;
    usz queue_count = 0;
    long[128] dequeued = zeroed;
    usz dequeued_count = 0;
    for (usz i = 0; i < (usz)operation_count; i++) {
        long opcode = input[1 + 2 * i], argument = input[2 + 2 * i];
        if (opcode == 0) {
            if (argument < -2147483648 || argument > 2147483647 || queue_count == 100) return -1;
            queue[queue_count++] = (int)argument;
        } else if (opcode == 1) {
            if (argument != 0 || queue_count == 0) return -1;
            usz minimum = 0;
            for (usz j = 1; j < queue_count; j++) if (queue[j] < queue[minimum]) minimum = j;
            dequeued[dequeued_count++] = (long)queue[minimum];
            queue_count--;
            for (usz j = minimum; j < queue_count; j++) queue[j] = queue[j + 1];
        } else return -1;
    }
    usz output_bytes = dequeued_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < dequeued_count; i++) store_i64(output, i * 8, dequeued[i]);
    return (long)output_bytes;
}
