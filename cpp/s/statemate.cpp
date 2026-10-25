/* Clean-room bounded profile of Embench-IoT Statemate's fixed control path. */
/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <stddef.h>
#include <stdint.h>

enum { STATE_COUNT = 16, BITLIST_COUNT = 64, TIMER_COUNT = 3,
       OUTPUT_BYTES = 64 + 16 + 12, MAX_RUNS = 256 };

static const uint8_t default_states[STATE_COUNT] = {
    0, 0, 0, 3, 2, 1, 1, 0, 0, 0, 0, 0, 2, 1, 0, 1
};

static void settle(uint8_t *snapshot) {
    uint8_t bitlist[BITLIST_COUNT] = {0};
    uint8_t states[STATE_COUNT] = {0};
    uint8_t timers[TIMER_COUNT * 4] = {0};
    int stable = 0;
    while (!stable) {
        stable = 1;
        for (size_t i = 0; i < STATE_COUNT; ++i) {
            if (states[i] == 0 && default_states[i] != 0) {
                states[i] = default_states[i];
                stable = 0;
            }
        }
    }
    bitlist[5] = 1;
    for (size_t i = 0; i < BITLIST_COUNT; ++i) snapshot[i] = bitlist[i];
    for (size_t i = 0; i < STATE_COUNT; ++i) snapshot[BITLIST_COUNT + i] = states[i];
    for (size_t i = 0; i < TIMER_COUNT * 4; ++i)
        snapshot[BITLIST_COUNT + STATE_COUNT + i] = timers[i];
}

extern "C" int64_t statemate(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > MAX_RUNS) return -1;
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;
    uint8_t staged[OUTPUT_BYTES] = {0};
    for (int64_t run = 0; run < input[0]; ++run) settle(staged);
    for (size_t i = 0; i < OUTPUT_BYTES; ++i) output[i] = staged[i];
    return OUTPUT_BYTES;
}
