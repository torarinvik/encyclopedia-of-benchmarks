// Clean-room bounded profile of Embench-IoT Statemate's fixed control path.
// SPDX-License-Identifier: GPL-3.0-or-later
module statemate;

const usz STATE_COUNT = 16;
const usz BITLIST_COUNT = 64;
const usz TIMER_BYTES = 12;
const usz OUTPUT_BYTES = BITLIST_COUNT + STATE_COUNT + TIMER_BYTES;
const long MAX_RUNS = 256;
const uchar[STATE_COUNT] DEFAULT_STATES = {0, 0, 0, 3, 2, 1, 1, 0, 0, 0, 0, 0, 2, 1, 0, 1};

fn void settle(uchar* snapshot) {
    uchar[BITLIST_COUNT] bitlist = {};
    uchar[STATE_COUNT] states = {};
    uchar[TIMER_BYTES] timers = {};
    bool stable = false;
    while (!stable) {
        stable = true;
        for (usz i = 0; i < STATE_COUNT; i++) {
            if (states[i] == 0 && DEFAULT_STATES[i] != 0) {
                states[i] = DEFAULT_STATES[i];
                stable = false;
            }
        }
    }
    bitlist[5] = 1;
    for (usz i = 0; i < BITLIST_COUNT; i++) snapshot[i] = bitlist[i];
    for (usz i = 0; i < STATE_COUNT; i++) snapshot[BITLIST_COUNT + i] = states[i];
    for (usz i = 0; i < TIMER_BYTES; i++) snapshot[BITLIST_COUNT + STATE_COUNT + i] = timers[i];
}

fn long statemate(long* input, usz length, uchar* output, usz capacity) @export("statemate") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > MAX_RUNS) return -1;
    if (output == null || capacity < OUTPUT_BYTES) return -2;
    uchar[OUTPUT_BYTES] staged = {};
    for (usz run = 0; run < (usz)input[0]; run++) settle(&staged[0]);
    for (usz i = 0; i < OUTPUT_BYTES; i++) output[i] = staged[i];
    return (long)OUTPUT_BYTES;
}
