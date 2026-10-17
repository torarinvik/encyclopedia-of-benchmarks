module multi_level_feedback_queue;

const usz MAX_QUEUES = 4;
const usz MAX_PROCESSES = 8;
const usz MAX_INPUT_WORDS = 13;
const usz MAX_OUTPUT_WORDS = 1 + 4 * MAX_PROCESSES;
const usz MAX_OUTPUT_BYTES = 4 * MAX_OUTPUT_WORDS;

struct Process {
    int id;
    int remaining;
    int waiting;
    int turnaround;
    int stop_time;
}

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long multi_level_feedback_queue(int* input, usz length, char* output, usz output_capacity)
        @export("multi_level_feedback_queue") {
    if (input == null || length < 2 || length > MAX_INPUT_WORDS) return -1;
    int queue_count = input[0], process_count = input[1];
    if (queue_count < 1 || queue_count > 4 || process_count < 0 || process_count > 8 ||
        length != (usz)(2 + queue_count - 1 + process_count)) return -1;

    int[3] slices;
    usz position = 2;
    usz queue_total = (usz)queue_count, process_total = (usz)process_count;
    for (usz i = 0; i < queue_total - 1; i += 1) {
        if (input[position] < 1 || input[position] > 16) return -1;
        slices[i] = (int)input[position++];
    }
    Process[8] ready;
    usz ready_count = process_total;
    for (usz i = 0; i < process_total; i += 1) {
        int burst = input[position++];
        if (burst < 1 || burst > 16) return -1;
        ready[i] = { (int)i, burst, 0, 0, 0 };
    }
    Process[8] finished;
    usz finished_count = 0;
    int current_time = 0;
    for (usz level = 0; level < queue_total - 1; level += 1) {
        Process[8] next_ready;
        usz next_count = 0;
        int time_slice = slices[level];
        for (usz i = 0; i < ready_count; i += 1) {
            Process process = ready[i];
            process.waiting += current_time - process.stop_time;
            if (process.remaining > time_slice) {
                current_time += time_slice;
                process.remaining -= time_slice;
                process.stop_time = current_time;
                next_ready[next_count++] = process;
            } else {
                current_time += process.remaining;
                process.remaining = 0;
                process.stop_time = current_time;
                process.turnaround = current_time;
                finished[finished_count++] = process;
            }
        }
        ready_count = next_count;
        for (usz i = 0; i < next_count; i += 1) ready[i] = next_ready[i];
    }
    for (usz i = 0; i < ready_count; i += 1) {
        Process process = ready[i];
        process.waiting += current_time - process.stop_time;
        current_time += process.remaining;
        process.remaining = 0;
        process.stop_time = current_time;
        process.turnaround = current_time;
        finished[finished_count++] = process;
    }
    if (finished_count != (usz)process_count) return -1;
    int[33] words;
    usz word_count = 1;
    words[0] = (int)process_count;
    for (usz i = 0; i < finished_count; i += 1) {
        words[word_count++] = finished[i].id;
        words[word_count++] = finished[i].waiting;
        words[word_count++] = finished[i].turnaround;
        words[word_count++] = finished[i].stop_time;
    }
    usz bytes = word_count * 4;
    if (bytes > MAX_OUTPUT_BYTES || output == null || output_capacity < bytes) return -2;
    char[132] buffer;
    for (usz i = 0; i < word_count; i += 1) put_i32_le(&buffer[0], i * 4, words[i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
