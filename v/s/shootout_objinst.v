module shootout_objinst

const min_n = i64(-100000)
const max_n = i64(100000)
const output_bytes = 72

struct Toggle {
	state bool
	activate fn (mut Toggle)
	value fn (&Toggle) bool
}

struct NthToggle {
	state bool
	count_max int
	counter int
	activate fn (mut NthToggle)
	value fn (&NthToggle) bool
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

fn append_state(mut staged []u8, mut used int, state bool) {
	word := if state { 'true' } else { 'false' }
	for byte in word.bytes() {
		staged[used] = byte
		used++
	}
	staged[used] = 10
	used++
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

	mut staged := []u8{len: output_bytes}
	mut used := 0
	mut toggle_memory := new_toggle()
	for _ in 0 .. 5 {
		activate := toggle_memory[0].activate
		activate(mut toggle_memory[0])
		value := toggle_memory[0].value
		append_state(mut staged, mut used, value(&toggle_memory[0]))
	}
	toggle_memory.free()

	if n > 0 {
		for _ in 0 .. int(n) {
			mut extra := new_toggle()
			extra.free()
		}
	}

	staged[used] = 10
	used++
	mut nth_memory := new_nth_toggle()
	for _ in 0 .. 8 {
		activate := nth_memory[0].activate
		activate(mut nth_memory[0])
		value := nth_memory[0].value
		append_state(mut staged, mut used, value(&nth_memory[0]))
	}
	nth_memory.free()

	if n > 0 {
		for _ in 0 .. int(n) {
			mut extra := new_nth_toggle()
			extra.free()
		}
	}

	if used != output_bytes { return -1 }
	unsafe { for index in 0 .. used { output[index] = staged[index] } }
	return i64(used)
}
