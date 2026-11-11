module shootout_objinst

@[c_extern]

fn C.benchmark_observe_object(object voidptr)

const min_n = -100000
const max_n = 100000
const output_bytes = 72

struct Toggle {
mut:
	state bool
	activate fn (mut Toggle) = unsafe { nil }
	value fn (&Toggle) bool = unsafe { nil }
}

struct NthToggle {
mut:
	state bool
	count_max int
	counter int
	activate fn (mut NthToggle) = unsafe { nil }
	value fn (&NthToggle) bool = unsafe { nil }
}

fn toggle_activate(mut toggle Toggle) {
	toggle.state = !toggle.state
}
fn toggle_value(toggle &Toggle) bool { return toggle.state }

fn nth_toggle_activate(mut toggle NthToggle) {
	toggle.counter++
	if toggle.counter >= toggle.count_max {
		toggle.state = !toggle.state
		toggle.counter = 0
	}
}
fn nth_toggle_value(toggle &NthToggle) bool { return toggle.state }

fn append_state(staged &u8, start int, state bool) int {
	word := if state { 'true' } else { 'false' }
	mut used := start
	unsafe {
		for index in 0 .. word.len {
			staged[used] = word[index]
			used++
		}
		staged[used] = 10
	}
	return used + 1
}

fn new_toggle() []Toggle {
	mut memory := []Toggle{len: 1}
	memory[0] = Toggle{state: true, activate: toggle_activate, value: toggle_value}
	return memory
}

fn new_nth_toggle() []NthToggle {
	mut memory := []NthToggle{len: 1}
	memory[0] = NthToggle{
		state: true, count_max: 3, counter: 0,
		activate: nth_toggle_activate, value: nth_toggle_value,
	}
	return memory
}

@[export: 'shootout_objinst']
pub fn shootout_objinst(n i64, mut output &u8, output_capacity usize) i64 {
	if n < min_n || n > max_n { return -1 }
	if unsafe { output == nil } || output_capacity < output_bytes { return -2 }

	mut staged := [output_bytes]u8{}
	mut used := 0
	mut toggle_memory := new_toggle()
	for _ in 0 .. 5 {
		activate := toggle_memory[0].activate
		activate(mut toggle_memory[0])
		value := toggle_memory[0].value
		used = append_state(&staged[0], used, value(unsafe { &toggle_memory[0] }))
	}
	unsafe { toggle_memory.free() }

	if n > 0 {
		for _ in 0 .. int(n) {
			mut extra := new_toggle()
			unsafe {
				C.benchmark_observe_object(&extra[0])
				extra.free()
			}
		}
	}

	staged[used] = 10
	used++
	mut nth_memory := new_nth_toggle()
	for _ in 0 .. 8 {
		activate := nth_memory[0].activate
		activate(mut nth_memory[0])
		value := nth_memory[0].value
		used = append_state(&staged[0], used, value(unsafe { &nth_memory[0] }))
	}
	unsafe { nth_memory.free() }

	if n > 0 {
		for _ in 0 .. int(n) {
			mut extra := new_nth_toggle()
			unsafe {
				C.benchmark_observe_object(&extra[0])
				extra.free()
			}
		}
	}

	if used != output_bytes { return -1 }
	unsafe { for index in 0 .. used { output[index] = staged[index] } }
	return i64(used)
}
