module versabench_dbms_choose_entry

const max_children = 8
const max_input_length = 1 + 8 * max_children + 8

fn valid_box(values &i64, at int) bool {
	unsafe { for d in 0 .. 4 { if values[at + d] < -8 || values[at + d] > 8 || values[at + 4 + d] < -8 || values[at + 4 + d] > 8 || values[at + d] >= values[at + 4 + d] { return false } } }
	return true
}

fn volume_at(values &i64, at int) i64 {
	mut result := i64(1)
	unsafe { for d in 0 .. 4 { result *= values[at + 4 + d] - values[at + d] } }
	return result
}

fn penalty_at(values &i64, child int, incoming int) i64 {
	mut joined_volume := i64(1)
	unsafe {
		for d in 0 .. 4 {
			lo := if values[child + d] < values[incoming + d] { values[child + d] } else { values[incoming + d] }
			hi := if values[child + 4 + d] > values[incoming + 4 + d] { values[child + 4 + d] } else { values[incoming + 4 + d] }
			joined_volume *= hi - lo
		}
	}
	return joined_volume - volume_at(values, child)
}

@[export: 'versabench_dbms_choose_entry']
pub fn versabench_dbms_choose_entry(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > usize(max_input_length + 1) { return -1 }
		raw_count := values[0]
		if raw_count < 1 || raw_count > max_children { return -1 }
		count := int(raw_count)
		if length != usize(1 + 8 * count + 8) { return -1 }
		incoming := 1 + 8 * count
		for i in 0 .. count { if !valid_box(values, 1 + 8 * i) { return -1 } }
		if !valid_box(values, incoming) { return -1 }
		mut best := 0
		mut best_penalty := penalty_at(values, 1, incoming)
		for i in 1 .. count {
			candidate := penalty_at(values, 1 + 8 * i, incoming)
			if candidate < best_penalty { best = i; best_penalty = candidate }
		}
		return i64(best)
	}
}
