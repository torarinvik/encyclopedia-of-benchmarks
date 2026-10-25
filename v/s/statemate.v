// Clean-room bounded profile of Embench-IoT Statemate's fixed control path.
// SPDX-License-Identifier: GPL-3.0-or-later
module statemate

const state_count = 16
const bitlist_count = 64
const timer_bytes = 12
const output_bytes = bitlist_count + state_count + timer_bytes
const max_runs = 256

fn default_state(index int) u8 {
	match index {
		3 { return 3 }
		4, 12 { return 2 }
		5, 6, 9, 13, 15 { return 1 }
		else { return 0 }
	}
}

fn settle(mut snapshot [output_bytes]u8) {
	mut bitlist := [bitlist_count]u8{}
	mut states := [state_count]u8{}
	mut timers := [timer_bytes]u8{}
	mut stable := false
	for !stable {
		stable = true
		for index in 0 .. state_count {
			target := default_state(index)
			if states[index] == 0 && target != 0 {
				states[index] = target
				stable = false
			}
		}
	}
	bitlist[5] = 1
	for index in 0 .. bitlist_count { snapshot[index] = bitlist[index] }
	for index in 0 .. state_count { snapshot[bitlist_count + index] = states[index] }
	for index in 0 .. timer_bytes { snapshot[bitlist_count + state_count + index] = timers[index] }
}

@[export: 'statemate']
pub fn statemate(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	run_count := unsafe { input[0] }
	if run_count < 1 || run_count > max_runs { return -1 }
	if unsafe { output == nil } || capacity < output_bytes { return -2 }
	mut staged := [output_bytes]u8{}
	for _ in 0 .. int(run_count) { settle(mut staged) }
	unsafe {
		for index in 0 .. output_bytes { output[index] = staged[index] }
	}
	return i64(output_bytes)
}
