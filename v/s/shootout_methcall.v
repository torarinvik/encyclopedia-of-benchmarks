const min_calls = -100000
const max_calls = 100000
const max_output_bytes = 14

struct Toggle {
mut:
	state bool
	activate fn (mut Toggle) @[required]
	value fn (&Toggle) bool @[required]
}

struct NthToggle {
	count_max int
mut:
	state bool
	counter int
	activate fn (mut NthToggle) @[required]
	value fn (&NthToggle) bool @[required]
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
		used++
		staged[used] = 10
	}
	return used + 1
}

@[export: 'shootout_methcall']
pub fn shootout_methcall(calls i64, mut output &u8, output_capacity usize) i64 {
	if calls < min_calls || calls > max_calls { return -1 }
	if unsafe { output == nil } { return -2 }
	mut toggle := Toggle{state: true, activate: toggle_activate, value: toggle_value}
	mut nth_toggle := NthToggle{
		state: true, count_max: 3, counter: 0,
		activate: nth_toggle_activate, value: nth_toggle_value,
	}
	mut toggle_result := true
	mut nth_result := true
	if calls > 0 {
		for _ in 0 .. int(calls) {
			activate := toggle.activate
			activate(mut toggle)
			value := toggle.value
			toggle_result = value(&toggle)
		}
		for _ in 0 .. int(calls) {
			activate := nth_toggle.activate
			activate(mut nth_toggle)
			value := nth_toggle.value
			nth_result = value(&nth_toggle)
		}
	}
	mut staged := [max_output_bytes]u8{}
	mut used := 0
	used = append_state(&staged[0], used, toggle_result)
	used = append_state(&staged[0], used, nth_result)
	if output_capacity < usize(used) { return -2 }
	unsafe { for index in 0 .. used { output[index] = staged[index] } }
	return i64(used)
}
