module problem114

const max_length = 50

@[export: 'problem114']
pub fn problem114(length i64) i64 {
	if length < 0 || length > max_length { return -1 }
	mut ways := [max_length + 1]i64{}
	for index in 0 .. int(length) + 1 { ways[index] = 1 }
	for row_length in 3 .. int(length) + 1 {
		for block_length in 3 .. row_length + 1 {
			for block_start in 0 .. (row_length - block_length) {
				ways[row_length] += ways[row_length - block_start - block_length - 1]
			}
			ways[row_length]++
		}
	}
	return ways[int(length)]
}
