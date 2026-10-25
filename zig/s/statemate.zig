// Clean-room bounded profile of Embench-IoT Statemate's fixed control path.
// SPDX-License-Identifier: GPL-3.0-or-later
const STATE_COUNT: usize = 16;
const BITLIST_COUNT: usize = 64;
const TIMER_BYTES: usize = 12;
const OUTPUT_BYTES: usize = BITLIST_COUNT + STATE_COUNT + TIMER_BYTES;
const MAX_RUNS: i64 = 256;

fn defaultState(index: usize) u8 {
    return switch (index) {
        3 => 3,
        4, 12 => 2,
        5, 6, 9, 13, 15 => 1,
        else => 0,
    };
}

fn settle(snapshot: *[OUTPUT_BYTES]u8) void {
    var bitlist: [BITLIST_COUNT]u8 = .{0} ** BITLIST_COUNT;
    var states: [STATE_COUNT]u8 = .{0} ** STATE_COUNT;
    const timers: [TIMER_BYTES]u8 = .{0} ** TIMER_BYTES;
    var stable = false;
    while (!stable) {
        stable = true;
        for (0..STATE_COUNT) |index| {
            const target = defaultState(index);
            if (states[index] == 0 and target != 0) {
                states[index] = target;
                stable = false;
            }
        }
    }
    bitlist[5] = 1;
    @memcpy(snapshot[0..BITLIST_COUNT], bitlist[0..]);
    @memcpy(snapshot[BITLIST_COUNT .. BITLIST_COUNT + STATE_COUNT], states[0..]);
    @memcpy(snapshot[BITLIST_COUNT + STATE_COUNT ..], timers[0..]);
}

pub export fn statemate(input: [*c]const i64, length: usize,
                        output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 1 or input[0] < 1 or input[0] > MAX_RUNS) return -1;
    if (output == null or capacity < OUTPUT_BYTES) return -2;
    var staged: [OUTPUT_BYTES]u8 = .{0} ** OUTPUT_BYTES;
    const runs: usize = @intCast(input[0]);
    for (0..runs) |_| settle(&staged);
    for (0..OUTPUT_BYTES) |index| output[index] = staged[index];
    return @intCast(OUTPUT_BYTES);
}
