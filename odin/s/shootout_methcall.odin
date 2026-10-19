package shootout_methcall

import "core:c"

MIN_CALLS :: i64(-100000)
MAX_CALLS :: i64(100000)
MAX_OUTPUT_BYTES :: 14

Toggle :: struct {
	state: bool,
	activate: proc(toggle: ^Toggle),
	value: proc(toggle: ^Toggle) -> bool,
}
NthToggle :: struct {
	state: bool,
	count_max: i32,
	counter: i32,
	activate: proc(toggle: ^NthToggle),
	value: proc(toggle: ^NthToggle) -> bool,
}

toggle_activate :: proc(toggle: ^Toggle) {
	toggle.state = !toggle.state
}

toggle_value :: proc(toggle: ^Toggle) -> bool { return toggle.state }

nth_toggle_activate :: proc(toggle: ^NthToggle) {
	toggle.counter += 1
	if toggle.counter >= toggle.count_max {
		toggle.state = !toggle.state
		toggle.counter = 0
	}
}

nth_toggle_value :: proc(toggle: ^NthToggle) -> bool { return toggle.state }

append_state :: proc(staged: [^]u8, used: ^int, state: bool) {
	word := if state { "true" } else { "false" }
	for byte in transmute([]u8)word {
		staged[used^] = byte
		used^ += 1
	}
	staged[used^] = 10
	used^ += 1
	staged[used^] = 10
	used^ += 1
}

@(export)
shootout_methcall :: proc "c" (calls: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if calls < MIN_CALLS || calls > MAX_CALLS do return -1
	if output == nil do return -2
	var toggle := Toggle{state = true, activate = toggle_activate, value = toggle_value}
	var nth_toggle := NthToggle{
		state = true, count_max = 3, counter = 0,
		activate = nth_toggle_activate, value = nth_toggle_value,
	}
	toggle_result, nth_result := true, true
	if calls > 0 {
		for _ in 0..<int(calls) {
			toggle.activate(&toggle)
			toggle_result = toggle.value(&toggle)
		}
		for _ in 0..<int(calls) {
			nth_toggle.activate(&nth_toggle)
			nth_result = nth_toggle.value(&nth_toggle)
		}
	}
	var staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	append_state(&staged[0], &used, toggle_result)
	append_state(&staged[0], &used, nth_result)
	if output_capacity < c.size_t(used) do return -2
	for index in 0..<used { output[index] = staged[index] }
	return i64(used)
}
