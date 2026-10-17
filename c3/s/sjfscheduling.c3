module sjfscheduling;

const usz MAX_INPUT_LENGTH = 130;
const usz MAX_PROCESSES = 64;
const usz MAX_OUTPUT_BYTES = 256;

fn void write_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long sjfscheduling(int* input, usz length, char* output,
                   usz output_capacity) @export("sjfscheduling") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    int process_count_value = input[0];
    if (process_count_value < 0 || process_count_value > 64
        || length != 1 + 2 * (usz)process_count_value) return -1;
    usz process_count = (usz)process_count_value;

    int[MAX_PROCESSES] arrivals;
    int[MAX_PROCESSES] bursts;
    int[MAX_PROCESSES] order;
    bool[MAX_PROCESSES] completed = zeroed;
    usz cursor = 1;
    for (usz index = 0; index < process_count; index += 1) {
        int arrival = input[cursor++];
        int burst = input[cursor++];
        if (arrival < 0 || arrival > 255 || burst < 1 || burst > 255) return -1;
        arrivals[index] = arrival;
        bursts[index] = burst;
    }

    int current_time = 0;
    usz scheduled = 0;
    while (scheduled < process_count) {
        usz best = process_count;
        for (usz index = 0; index < process_count; index += 1) {
            if (completed[index] || arrivals[index] > current_time) continue;
            if (best == process_count || bursts[index] < bursts[best]
                || (bursts[index] == bursts[best]
                    && (arrivals[index] < arrivals[best]
                        || (arrivals[index] == arrivals[best] && index < best)))) {
                best = index;
            }
        }
        if (best == process_count) {
            current_time += 1;
        } else {
            order[scheduled++] = (int)best;
            completed[best] = true;
            current_time += bursts[best];
        }
    }

    usz output_bytes = process_count * 4;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < process_count; index += 1)
        write_i32_le(output, index * 4, order[index]);
    return (long)output_bytes;
}
