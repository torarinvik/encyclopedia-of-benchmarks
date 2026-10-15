module minimum_steps_to_one

const max_n = 10_000

@[export: 'minimum_steps_to_one']
pub fn minimum_steps_to_one(n i64) i64 {
	if n < 1 || n > max_n { return -1 }
	mut table := []i64{len: max_n + 1, init: 0}
	for index in 0 .. int(n + 1) { table[index] = n + 1 }
	table[1] = 0
	mut i := 1
	for i < int(n) {
		candidate := table[i] + 1
		if table[i + 1] > candidate { table[i + 1] = candidate }
		if i * 2 <= int(n) && table[i * 2] > candidate { table[i * 2] = candidate }
		if i * 3 <= int(n) && table[i * 3] > candidate { table[i * 3] = candidate }
		i++
	}
	return table[n]
}
