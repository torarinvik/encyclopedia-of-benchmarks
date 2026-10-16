module job_scheduling_with_deadline

const max_input = 513
const pack_base = i64(4_294_967_296)

@[export: 'job_scheduling_with_deadline']
pub fn job_scheduling_with_deadline(packed &i64, length usize) i64 {
	if unsafe { packed == nil } || length < 1 || length > max_input { return -1 }
	count_value := unsafe { packed[0] }
	if count_value < 0 || count_value > 128 || length != usize(1 + count_value * 4) { return -1 }
	count := int(count_value)

	mut ids := []i64{len: 128}
	mut arrivals := []i64{len: 128}
	mut deadlines := []i64{len: 128}
	mut profits := []i64{len: 128}
	mut max_deadline := i64(0)
	for i := 0; i < count; i++ {
		base := 1 + i * 4
		ids[i] = unsafe { packed[base] }
		arrivals[i] = unsafe { packed[base + 1] }
		deadlines[i] = unsafe { packed[base + 2] }
		profits[i] = unsafe { packed[base + 3] }
		if ids[i] < 0 || ids[i] > 2_147_483_647 ||
			arrivals[i] < 1 || arrivals[i] > 32 ||
			deadlines[i] < 1 || deadlines[i] > 32 ||
			profits[i] < -1_000_000 || profits[i] > 1_000_000 { return -1 }
		for previous := 0; previous < i; previous++ {
			if ids[previous] == ids[i] { return -1 }
		}
		if deadlines[i] > max_deadline { max_deadline = deadlines[i] }
	}

	// Stable insertion sort retains input order for equal profits.
	for i := 1; i < count; i++ {
		key_id := ids[i]
		key_arrival := arrivals[i]
		key_deadline := deadlines[i]
		key_profit := profits[i]
		mut position := i
		for position > 0 && profits[position - 1] < key_profit {
			ids[position] = ids[position - 1]
			arrivals[position] = arrivals[position - 1]
			deadlines[position] = deadlines[position - 1]
			profits[position] = profits[position - 1]
			position--
		}
		ids[position] = key_id
		arrivals[position] = key_arrival
		deadlines[position] = key_deadline
		profits[position] = key_profit
	}

	mut occupied := []bool{len: 32}
	mut scheduled := i64(0)
	mut total_profit := i64(0)
	for i := 0; i < count; i++ {
		if arrivals[i] > deadlines[i] { continue }
		mut last_slot := int(deadlines[i] - 1)
		if last_slot > int(max_deadline - 1) { last_slot = int(max_deadline - 1) }
		mut slot := last_slot
		for slot >= int(arrivals[i] - 1) {
			if !occupied[slot] {
				occupied[slot] = true
				scheduled++
				total_profit += profits[i]
				break
			}
			slot--
		}
	}
	mut low_word := total_profit
	if low_word < 0 { low_word += pack_base }
	return scheduled * pack_base + low_word
}
