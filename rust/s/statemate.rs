// Clean-room bounded profile of Embench-IoT Statemate's fixed control path.
// SPDX-License-Identifier: GPL-3.0-or-later
const STATE_COUNT: usize = 16;
const BITLIST_COUNT: usize = 64;
const TIMER_BYTES: usize = 12;
const OUTPUT_BYTES: usize = BITLIST_COUNT + STATE_COUNT + TIMER_BYTES;
const MAX_RUNS: i64 = 256;
const DEFAULT_STATES: [u8; STATE_COUNT] = [0, 0, 0, 3, 2, 1, 1, 0, 0, 0, 0, 0, 2, 1, 0, 1];

fn settle(snapshot: &mut [u8; OUTPUT_BYTES]) {
    let mut bitlist = [0u8; BITLIST_COUNT];
    let mut states = [0u8; STATE_COUNT];
    let timers = [0u8; TIMER_BYTES];
    let mut stable = false;
    while !stable {
        stable = true;
        for index in 0..STATE_COUNT {
            let target = DEFAULT_STATES[index];
            if states[index] == 0 && target != 0 {
                states[index] = target;
                stable = false;
            }
        }
    }
    bitlist[5] = 1;
    snapshot[..BITLIST_COUNT].copy_from_slice(&bitlist);
    snapshot[BITLIST_COUNT..BITLIST_COUNT + STATE_COUNT].copy_from_slice(&states);
    snapshot[BITLIST_COUNT + STATE_COUNT..].copy_from_slice(&timers);
}

#[no_mangle]
pub unsafe extern "C" fn statemate(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 || *input < 1 || *input > MAX_RUNS { return -1; }
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }
    let mut staged = [0u8; OUTPUT_BYTES];
    for _ in 0..*input { settle(&mut staged); }
    for index in 0..OUTPUT_BYTES { output.add(index).write(staged[index]); }
    OUTPUT_BYTES as i64
}
