#include <stddef.h>
#include <stdint.h>

#define MAX_PACKETS 16
#define MAX_SLOTS 8
#define MAX_INPUT 38
#define MAX_OUTPUT_BYTES 64
#define BETA 15

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void erase_packet(int64_t *ids, int64_t *values, size_t *count, size_t index) {
    for (size_t position = index; position + 1 < *count; ++position) {
        ids[position] = ids[position + 1];
        values[position] = values[position + 1];
    }
    --*count;
}

int64_t packet_switching_single_buffer(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT) return -1;
    const int64_t mode = input[0], buffer_value = input[1], beta = input[2], slots_value = input[3], count_value = input[4];
    if (mode < 0 || mode > 2 || buffer_value < 1 || buffer_value > 4 || slots_value < 1 || slots_value > MAX_SLOTS ||
        count_value < 0 || count_value > MAX_PACKETS || length != 5 + 2 * (size_t)count_value ||
        (mode == 0 ? beta != 0 : beta != BETA)) return -1;
    const size_t slots = (size_t)slots_value, packet_count = (size_t)count_value;
    const int64_t buffer = buffer_value;
    int64_t arrival[MAX_PACKETS], packet_value[MAX_PACKETS];
    int64_t previous_slot = -1;
    for (size_t packet = 0; packet < packet_count; ++packet) {
        arrival[packet] = input[5 + 2 * packet];
        packet_value[packet] = input[6 + 2 * packet];
        if (arrival[packet] < 0 || arrival[packet] >= slots_value || arrival[packet] < previous_slot ||
            packet_value[packet] < 1 || packet_value[packet] > 100) return -1;
        previous_slot = arrival[packet];
    }
    int64_t resident_id[MAX_PACKETS], resident_value[MAX_PACKETS], schedule[MAX_SLOTS];
    size_t resident_count = 0, next_packet = 0;
    for (size_t slot = 0; slot < slots; ++slot) {
        while (next_packet < packet_count && arrival[next_packet] == (int64_t)slot) {
            const int64_t value = packet_value[next_packet];
            size_t preempt = resident_count;
            if (mode == 1) {
                for (size_t index = 0; index < resident_count; ++index) {
                    if (resident_value[index] * BETA <= value) { preempt = index; break; }
                }
            } else if (mode == 2) {
                for (size_t index = 0; index < resident_count; ++index) {
                    const int following_ok = index + 1 == resident_count || resident_value[index] <= resident_value[index + 1];
                    if (resident_value[index] * BETA < value && following_ok) { preempt = index; break; }
                }
            }
            if (preempt < resident_count) {
                erase_packet(resident_id, resident_value, &resident_count, preempt);
                resident_id[resident_count] = (int64_t)next_packet;
                resident_value[resident_count++] = value;
            } else if (resident_count < (size_t)buffer) {
                resident_id[resident_count] = (int64_t)next_packet;
                resident_value[resident_count++] = value;
            } else {
                int64_t smallest = resident_value[0];
                for (size_t index = 1; index < resident_count; ++index) if (resident_value[index] < smallest) smallest = resident_value[index];
                if (value > smallest) {
                    size_t evict = 0;
                    while (resident_value[evict] != smallest) ++evict;
                    erase_packet(resident_id, resident_value, &resident_count, evict);
                    resident_id[resident_count] = (int64_t)next_packet;
                    resident_value[resident_count++] = value;
                }
            }
            ++next_packet;
        }
        if (resident_count > 0) {
            schedule[slot] = resident_id[0];
            erase_packet(resident_id, resident_value, &resident_count, 0);
        } else schedule[slot] = -1;
    }
    const size_t output_bytes = 8 * slots;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t slot = 0; slot < slots; ++slot) store_i64_le(staged, 8 * slot, schedule[slot]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
