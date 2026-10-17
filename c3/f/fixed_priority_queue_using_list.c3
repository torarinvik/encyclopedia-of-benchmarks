module fixed_priority_queue_using_list;

void store_i64(char* output, usz offset, long value) { ulong bits = @bitcast(ulong, value); for (usz i = 0; i < 8; i++) output[offset + i] = (char)(bits >> (8 * i)); }

fn long fixed_priority_queue_using_list(long* input, usz length, char* output, usz capacity)
    @export("fixed_priority_queue_using_list") {
    if (input == null || length < 1 || length > 770) return -1;
    long operation_count = input[0];
    if (operation_count < 0 || operation_count > 256 || length != 1 + 3 * (usz)operation_count) return -1;
    int[3][100] buckets = zeroed;
    usz[3] counts = zeroed;
    long[128] dequeued = zeroed;
    usz dequeued_count = 0;
    for (usz i = 0; i < (usz)operation_count; i++) {
        long opcode = input[1 + 3 * i], priority = input[2 + 3 * i], data = input[3 + 3 * i];
        if (opcode == 0) {
            if (priority < -3 || priority > 2 || data < -2147483648 || data > 2147483647) return -1;
            usz bucket = (usz)(priority < 0 ? priority + 3 : priority);
            if (counts[bucket] == 100) return -1;
            buckets[bucket][counts[bucket]++] = (int)data;
        } else if (opcode == 1) {
            if (priority != 0 || data != 0) return -1;
            usz bucket = 0;
            while (bucket < 3 && counts[bucket] == 0) bucket++;
            if (bucket == 3) return -1;
            dequeued[dequeued_count++] = (long)buckets[bucket][0];
            counts[bucket]--;
            for (usz j = 0; j < counts[bucket]; j++) buckets[bucket][j] = buckets[bucket][j + 1];
        } else return -1;
    }
    usz output_bytes = dequeued_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < dequeued_count; i++) store_i64(output, i * 8, dequeued[i]);
    return (long)output_bytes;
}
