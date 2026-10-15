module circular_buffer;

fn long circular_buffer_benchmark(long* values, usz length) @export("circular_buffer_benchmark") {
    if (values == null || length < 1 || length > 1025 || (length - 1) % 2 != 0) return -1;
    if (values[0] < 1 || values[0] > 256) return -1;
    usz capacity = (usz)values[0];
    usz operation_count = (length - 1) / 2;
    long[256] buffer;
    usz head = 0, tail = 0, count = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = values[1 + 2 * operation], payload = values[2 + 2 * operation];
        long observed = 0;
        if (opcode == 0) {
            if (payload < 0 || payload > 1000000) return -1;
            bool was_empty = count == 0;
            if (count == capacity) head = (head + 1) % capacity;
            else count++;
            buffer[tail] = payload;
            tail = (tail + 1) % capacity;
            observed = (long)was_empty;
        } else if (opcode == 1) {
            if (payload != 0) return -1;
            if (count == 0) observed = -1;
            else {
                observed = buffer[head];
                head = (head + 1) % capacity;
                count--;
            }
        } else if (opcode == 2) {
            if (payload != 0) return -1;
            observed = (long)(count == 0);
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = (long)(count == capacity);
        } else if (opcode == 4) {
            if (payload != 0) return -1;
            observed = count.long();
        } else return -1;
        checksum += (long)(operation + 1) * (observed + 1000000);
    }
    for (usz index = 0; index < count; index++)
        checksum += (long)(operation_count + index + 1) * (buffer[(head + index) % capacity] + 1000000);
    return checksum;
}
