module self_adjusting_scheduling

const max_tasks = 16
const max_steps = 64
const max_input_length = max_tasks + 3

@[export: 'self_adjusting_scheduling']
pub fn self_adjusting_scheduling(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	unsafe {
		task_count_value, steps_value := input[0], input[1]
		if task_count_value < 1 || task_count_value > max_tasks || steps_value < 0 || steps_value > max_steps || length != usize(task_count_value) + 2 { return -1 }
		task_count, steps := int(task_count_value), int(steps_value)
		mut priorities := [max_tasks]i64{}
		mut wait_times := [max_tasks]i64{}
		mut schedule := [max_steps]u8{}
		for task in 0 .. task_count {
			priority := input[task + 2]
			if priority < i64(-2147483648) || priority > i64(2147483647) { return -1 }
			priorities[task] = priority
		}
		for step in 0 .. steps {
			for left in 0 .. task_count {
				for right in left + 1 .. task_count {
					if priorities[left] == priorities[right] { return -1 }
				}
			}
			mut selected := 0
			for task in 1 .. task_count {
				if priorities[task] < priorities[selected] { selected = task }
			}
			schedule[step] = u8(selected)
			wait_times[selected] += 1
			updated_priority := priorities[selected] + wait_times[selected]
			if updated_priority < i64(-2147483648) || updated_priority > i64(2147483647) { return -1 }
			priorities[selected] = updated_priority
		}
		if output == nil || capacity < usize(steps) { return -2 }
		for step in 0 .. steps { output[step] = schedule[step] }
		return i64(steps)
	}
}
