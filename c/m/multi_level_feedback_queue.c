#include <stddef.h>
#include <stdint.h>

#define MAX_QUEUES 4
#define MAX_PROCESSES 8
#define MAX_INPUT_WORDS 13
#define MAX_OUTPUT_WORDS (1 + 4 * MAX_PROCESSES)
#define MAX_OUTPUT_BYTES (4 * MAX_OUTPUT_WORDS)

typedef struct {
    int32_t id, remaining, waiting, turnaround, stop_time;
} Process;

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t multi_level_feedback_queue(const int32_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int32_t queue_count = input[0], process_count = input[1];
    if (queue_count < 1 || queue_count > MAX_QUEUES || process_count < 0 || process_count > MAX_PROCESSES ||
        length != 2 + (size_t)(queue_count - 1) + (size_t)process_count) return -1;

    int32_t slices[MAX_QUEUES - 1] = {0};
    size_t pos = 2;
    for (int32_t i = 0; i < queue_count - 1; ++i) {
        if (input[pos] < 1 || input[pos] > 16) return -1;
        slices[i] = input[pos++];
    }
    Process ready[MAX_PROCESSES] = {0};
    size_t ready_count = (size_t)process_count;
    for (int32_t i = 0; i < process_count; ++i) {
        const int32_t burst = input[pos++];
        if (burst < 1 || burst > 16) return -1;
        ready[i] = (Process){i, burst, 0, 0, 0};
    }

    Process finished[MAX_PROCESSES] = {0};
    size_t finished_count = 0;
    int32_t current_time = 0;
    for (int32_t level = 0; level < queue_count - 1; ++level) {
        Process next_ready[MAX_PROCESSES] = {0};
        size_t next_count = 0;
        const int32_t time_slice = slices[level];
        for (size_t i = 0; i < ready_count; ++i) {
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
        for (size_t i = 0; i < next_count; ++i) ready[i] = next_ready[i];
    }
    for (size_t i = 0; i < ready_count; ++i) {
        Process process = ready[i];
        process.waiting += current_time - process.stop_time;
        current_time += process.remaining;
        process.remaining = 0;
        process.stop_time = current_time;
        process.turnaround = current_time;
        finished[finished_count++] = process;
    }

    if (finished_count != (size_t)process_count) return -1;
    int32_t words[MAX_OUTPUT_WORDS] = {0};
    size_t word_count = 1;
    words[0] = process_count;
    for (size_t i = 0; i < finished_count; ++i) {
        words[word_count++] = finished[i].id;
        words[word_count++] = finished[i].waiting;
        words[word_count++] = finished[i].turnaround;
        words[word_count++] = finished[i].stop_time;
    }
    const size_t bytes = word_count * 4;
    if (bytes > MAX_OUTPUT_BYTES || output == NULL || capacity < bytes) return -2;
    uint8_t buffer[MAX_OUTPUT_BYTES];
    for (size_t i = 0; i < word_count; ++i) put_i32_le(buffer, i * 4, words[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return (int64_t)bytes;
}
