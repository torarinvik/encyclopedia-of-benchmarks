#include <stddef.h>
#include <stdint.h>

enum { MAX_NODES = 16, MAX_BITS = 6, MAX_INPUT = 116, MAX_OUTPUT = 128 };

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[at + i] = (uint8_t)(bits & 255u); bits >>= 8; }
}

int64_t p2p_chord_finger_lookup(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_BITS || input[1] < 2 || input[1] > MAX_NODES) return -1;
    int bits = (int)input[0], n = (int)input[1];
    if (n > (1 << bits) || input[2] < 0 || input[2] >= n || input[3] < 0 || input[3] >= (1 << bits)) return -1;
    int start = (int)input[2];
    if (length != (size_t)(4 + n + n * bits)) return -1;
    int ids[MAX_NODES], fingers[MAX_NODES * MAX_BITS];
    for (int i = 0; i < n; ++i) {
        int64_t raw = input[4 + i];
        if (raw < 0 || raw >= (1 << bits) || (i > 0 && raw <= ids[i - 1])) return -1;
        ids[i] = (int)raw;
    }
    int ring = 1 << bits;
    for (int node = 0; node < n; ++node) {
        for (int level = 0; level < bits; ++level) {
            int64_t raw_pointer = input[4 + n + node * bits + level];
            if (raw_pointer < 0 || raw_pointer >= n) return -1;
            int pointer = (int)raw_pointer;
            int target = (ids[node] + (1 << level)) % ring;
            int successor = 0;
            while (successor < n && ids[successor] < target) ++successor;
            if (successor == n) successor = 0;
            if (pointer != successor) return -1;
            fingers[node * bits + level] = pointer;
        }
    }
    int key = (int)input[3], owner = 0;
    while (owner < n && ids[owner] < key) ++owner;
    if (owner == n) owner = 0;
    int route[MAX_NODES], route_length = 1, current = start;
    route[0] = current;
    for (int step = 0; step < n; ++step) {
        if (current == owner) break;
        int target_distance = (ids[owner] - ids[current] + ring) % ring;
        int chosen = -1;
        for (int level = bits - 1; level >= 0; --level) {
            int candidate = fingers[current * bits + level];
            int progress = (ids[candidate] - ids[current] + ring) % ring;
            if (progress > 0 && progress <= target_distance) { chosen = candidate; break; }
        }
        if (chosen < 0 || route_length >= n) return -1;
        for (int i = 0; i < route_length; ++i) if (route[i] == chosen) return -1;
        current = chosen;
        route[route_length++] = current;
    }
    if (current != owner) return -1;
    size_t bytes = 8u * (size_t)route_length;
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT] = {0};
    for (int i = 0; i < route_length; ++i) put_i64(staged, 8u * (size_t)i, ids[route[i]]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
