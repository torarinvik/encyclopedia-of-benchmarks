#include <stddef.h>
#include <stdint.h>

#define MAX_QUEUES 4
#define MAX_SLOTS 8
#define MAX_INPUT 36
#define MAX_OUTPUT_BYTES 64

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t packet_switching_sgr_multi_queue(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t queue_value = input[0], buffer_value = input[1], slot_value = input[2];
    if (queue_value < 2 || queue_value > MAX_QUEUES || buffer_value < 1 || buffer_value > 4 ||
        slot_value < 1 || slot_value > MAX_SLOTS || length != 3 + (size_t)queue_value * (size_t)slot_value) return -1;
    const size_t queues = (size_t)queue_value, slots = (size_t)slot_value;
    const int64_t buffer = buffer_value;
    int64_t load[MAX_QUEUES] = {0}, peak[MAX_QUEUES] = {0}, schedule[MAX_SLOTS];
    for (size_t slot = 0; slot < slots; ++slot) {
        for (size_t queue = 0; queue < queues; ++queue) {
            const int64_t arrivals = input[3 + slot * queues + queue];
            if (arrivals < 0 || arrivals > buffer) return -1;
            load[queue] += arrivals;
            if (load[queue] > buffer) load[queue] = buffer;
            if (load[queue] > peak[queue]) peak[queue] = load[queue];
        }
        int has_large = 0, has_nonempty = 0, has_underfull_peak = 0;
        for (size_t queue = 0; queue < queues; ++queue) {
            if (load[queue] > 0) {
                has_nonempty = 1;
                if (load[queue] > buffer / 2) has_large = 1;
                if (peak[queue] < buffer) has_underfull_peak = 1;
            }
        }
        if (!has_nonempty) {
            schedule[slot] = -1;
            for (size_t queue = 0; queue < queues; ++queue) peak[queue] = 0;
            continue;
        }
        size_t selected = queues;
        int use_history = !has_large && has_underfull_peak;
        for (size_t queue = 0; queue < queues; ++queue) {
            if (load[queue] == 0 || (use_history && peak[queue] >= buffer)) continue;
            if (selected == queues || load[queue] > load[selected]) selected = queue;
        }
        schedule[slot] = (int64_t)selected;
        --load[selected];
        int any_left = 0;
        for (size_t queue = 0; queue < queues; ++queue) if (load[queue] > 0) any_left = 1;
        if (!any_left) for (size_t queue = 0; queue < queues; ++queue) peak[queue] = 0;
    }
    const size_t output_bytes = 8 * slots;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t slot = 0; slot < slots; ++slot) store_i64_le(staged, 8 * slot, schedule[slot]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
