package versabench_dbms_choose_entry
import "core:c"

MAX_CHILDREN :: 8
MAX_INPUT_LENGTH :: 1 + 8 * MAX_CHILDREN + 8

valid_box :: proc "contextless" (values: [^]i64, at: int) -> bool {
	for d := 0; d < 4; d += 1 {
		if values[at+d] < -8 || values[at+d] > 8 || values[at+4+d] < -8 || values[at+4+d] > 8 || values[at+d] >= values[at+4+d] { return false }
	}
	return true
}

volume_at :: proc "contextless" (values: [^]i64, at: int) -> i64 {
	result: i64 = 1
	for d := 0; d < 4; d += 1 { result *= values[at+4+d] - values[at+d] }
	return result
}

penalty_at :: proc "contextless" (values: [^]i64, child, incoming: int) -> i64 {
	joined_volume: i64 = 1
	for d := 0; d < 4; d += 1 {
		lo := values[child+d]
		if values[incoming+d] < lo { lo = values[incoming+d] }
		hi := values[child+4+d]
		if values[incoming+4+d] > hi { hi = values[incoming+4+d] }
		joined_volume *= hi - lo
	}
	return joined_volume - volume_at(values, child)
}

@(export, link_name="versabench_dbms_choose_entry")
versabench_dbms_choose_entry :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH+1) do return -1
	raw_count := values[0]
	if raw_count < 1 || raw_count > MAX_CHILDREN do return -1
	count := int(raw_count)
	if length != c.size_t(1+8*count+8) do return -1
	incoming := 1+8*count
	for i := 0; i < count; i += 1 { if !valid_box(values, 1+8*i) do return -1 }
	if !valid_box(values, incoming) do return -1
	best := 0
	best_penalty := penalty_at(values, 1, incoming)
	for i := 1; i < count; i += 1 {
		candidate := penalty_at(values, 1+8*i, incoming)
		if candidate < best_penalty { best = i; best_penalty = candidate }
	}
	return i64(best)
}
