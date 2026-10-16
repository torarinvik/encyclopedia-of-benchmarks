package problem114

const MAX_LENGTH = 50

@(export)
problem114 :: proc "c" (length: i64) -> i64 {
	if length < 0 || length > MAX_LENGTH do return -1
	ways: [MAX_LENGTH + 1]i64
	for index := 0; index <= int(length); index += 1 { ways[index] = 1 }
	for row_length := 3; row_length <= int(length); row_length += 1 {
		for block_length := 3; block_length <= row_length; block_length += 1 {
			for block_start := 0; block_start < row_length - block_length; block_start += 1 {
				ways[row_length] += ways[row_length - block_start - block_length - 1]
			}
			ways[row_length] += 1
		}
	}
	return ways[int(length)]
}
