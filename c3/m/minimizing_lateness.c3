module minimizing_lateness;

const usz MAX_JOBS = 64;
const usz MAX_OUTPUT = 4 + 12 * MAX_JOBS;

fn void write_i32(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long minimizing_lateness(long* input, usz length, char* output, usz capacity)
    @export("minimizing_lateness") {
    if (input == null || length < 1 || length > 1 + 2 * MAX_JOBS) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > 64 || length != 1 + 2 * (usz)count_value) return -1;
    usz count = (usz)count_value;
    int[MAX_JOBS] processing, deadlines, originals, starts, latenesses;
    long total_processing = 0;
    for (usz i = 0; i < count; i++) {
        long p = input[1 + 2 * i], d = input[2 + 2 * i];
        if (p < 0 || p > 2147483647 || d < 0 || d > 2147483647) return -1;
        total_processing += p;
        if (total_processing > 2147483647) return -1;
        processing[i] = (int)p;
        deadlines[i] = (int)d;
        originals[i] = (int)i;
    }
    // Stable insertion sort leaves equal deadlines in their source order.
    for (usz i = 1; i < count; i++) {
        int item_p = processing[i], item_d = deadlines[i], item_original = originals[i];
        usz position = i;
        while (position > 0 && deadlines[position - 1] > item_d) {
            processing[position] = processing[position - 1];
            deadlines[position] = deadlines[position - 1];
            originals[position] = originals[position - 1];
            position--;
        }
        processing[position] = item_p;
        deadlines[position] = item_d;
        originals[position] = item_original;
    }
    long start_time = 0;
    for (usz i = 0; i < count; i++) {
        starts[i] = (int)start_time;
        long finish_time = start_time + processing[i];
        long late = finish_time - deadlines[i];
        latenesses[i] = (int)(late > 0 ? late : 0);
        start_time = finish_time;
    }
    usz needed = 4 + 12 * count;
    if (output == null || capacity < needed) return -2;
    char[MAX_OUTPUT] payload;
    write_i32(&payload[0], 0, (int)count);
    for (usz i = 0; i < count; i++) {
        usz offset = 4 + 12 * i;
        write_i32(&payload[0], offset, originals[i]);
        write_i32(&payload[0], offset + 4, starts[i]);
        write_i32(&payload[0], offset + 8, latenesses[i]);
    }
    for (usz i = 0; i < needed; i++) output[i] = payload[i];
    return (long)needed;
}
