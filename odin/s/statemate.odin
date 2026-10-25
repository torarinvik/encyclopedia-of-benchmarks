// Clean-room bounded profile of Embench-IoT Statemate's fixed control path.
// SPDX-License-Identifier: GPL-3.0-or-later
package statemate

import "core:c"

STATE_COUNT :: 16
BITLIST_COUNT :: 64
TIMER_BYTES :: 12
OUTPUT_BYTES :: BITLIST_COUNT + STATE_COUNT + TIMER_BYTES
MAX_RUNS :: 256

default_state :: proc(index: int) -> u8 {
    switch index {
    case 3: return 3
    case 4, 12: return 2
    case 5, 6, 9, 13, 15: return 1
    }
    return 0
}

settle :: proc(snapshot: [^]u8) {
    bitlist: [BITLIST_COUNT]u8 = {}
    states: [STATE_COUNT]u8 = {}
    timers: [TIMER_BYTES]u8 = {}
    stable := false
    for !stable {
        stable = true
        for index := 0; index < STATE_COUNT; index += 1 {
            target := default_state(index)
            if states[index] == 0 && target != 0 {
                states[index] = target
                stable = false
            }
        }
    }
    bitlist[5] = 1
    for index := 0; index < BITLIST_COUNT; index += 1 { snapshot[index] = bitlist[index] }
    for index := 0; index < STATE_COUNT; index += 1 { snapshot[BITLIST_COUNT + index] = states[index] }
    for index := 0; index < TIMER_BYTES; index += 1 { snapshot[BITLIST_COUNT + STATE_COUNT + index] = timers[index] }
}

@(export)
statemate :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length != 1 || input[0] < 1 || input[0] > MAX_RUNS do return -1
    if output == nil || capacity < OUTPUT_BYTES do return -2
    staged: [OUTPUT_BYTES]u8 = {}
    for run := 0; run < int(input[0]); run += 1 { settle(&staged[0]) }
    for index := 0; index < OUTPUT_BYTES; index += 1 { output[index] = staged[index] }
    return i64(OUTPUT_BYTES)
}
