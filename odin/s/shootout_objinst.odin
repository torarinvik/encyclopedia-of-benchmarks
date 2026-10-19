package shootout_objinst

import "core:c"

MIN_N :: i64(-100000)
MAX_N :: i64(100000)
OUTPUT_BYTES :: 72

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
}

@(export)
shootout_objinst :: proc "c" (n: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if n < MIN_N || n > MAX_N do return -1
	if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2

	staged: [OUTPUT_BYTES]u8
	used := 0
	toggle_memory := make([]Toggle, 1)
	toggle := &toggle_memory[0]
	toggle^ = Toggle{state = true, activate = toggle_activate, value = toggle_value}
	for _ in 0..<5 {
		toggle.activate(toggle)
		append_state(&staged[0], &used, toggle.value(toggle))
	}
	delete(toggle_memory)

	if n > 0 {
		for _ in 0..<int(n) {
			extra_memory := make([]Toggle, 1)
			extra_memory[0] = Toggle{state = true, activate = toggle_activate, value = toggle_value}
			delete(extra_memory)
		}
	}

	staged[used] = 10
	used += 1
	nth_memory := make([]NthToggle, 1)
	nth_toggle := &nth_memory[0]
	nth_toggle^ = NthToggle{
		state = true, count_max = 3, counter = 0,
		activate = nth_toggle_activate, value = nth_toggle_value,
	}
	for _ in 0..<8 {
		nth_toggle.activate(nth_toggle)
		append_state(&staged[0], &used, nth_toggle.value(nth_toggle))
	}
	delete(nth_memory)

	if n > 0 {
		for _ in 0..<int(n) {
			extra_memory := make([]NthToggle, 1)
			extra_memory[0] = NthToggle{
				state = true, count_max = 3, counter = 0,
				activate = nth_toggle_activate, value = nth_toggle_value,
			}
			delete(extra_memory)
		}
	}

	if used != OUTPUT_BYTES do return -1
	for index in 0..<used { output[index] = staged[index] }
	return i64(used)
}
