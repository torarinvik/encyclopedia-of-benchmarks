module unrolled_linked_list

@[export: 'unrolled_linked_list_benchmark']
pub fn unrolled_linked_list_benchmark(values &i64, length usize) i64 {
	if length > 1024 { return -1 }
	mut chunks := [512][5]i64{}
	mut counts := [512]int{}
	mut next := [512]int{}
	for i in 0 .. 512 { next[i] = 512 }
	mut blocks := 0
	for i in 0 .. int(length) {
		value := unsafe { values[i] }
		if value < -1000000 || value > 1000000 { return -1 }
		if blocks == 0 { blocks = 1; counts[0] = 1; chunks[0][0] = value }
		else if counts[blocks - 1] < 4 { chunks[blocks - 1][counts[blocks - 1]] = value; counts[blocks - 1]++ }
		else {
			tail := blocks - 1
			keep := counts[tail] / 2 + 1
			moved := counts[tail] - keep
			for j in 0 .. moved { chunks[blocks][j] = chunks[tail][keep + j] }
			counts[tail] = keep; chunks[blocks][moved] = value; counts[blocks] = moved + 1; next[tail] = blocks; blocks++
		}
	}
	mut checksum := i64(0)
	mut index := 0
	mut b := 0
	for b < 512 { for j in 0 .. counts[b] { checksum += i64(index + 1) * (chunks[b][j] + 1000000); index++ }; if next[b] == 512 { break }; b = next[b] }
	return checksum
}
