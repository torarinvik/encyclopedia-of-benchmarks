module problem115

@[export: 'problem115']
pub fn problem115(min_block_length i64) i64 {
	if min_block_length < 1 || min_block_length > 100 { return -1 }
	mut ways := [1024]i64{}
	for i in 0 .. int(min_block_length) { ways[i] = 1 }
	for n in int(min_block_length) .. 1024 {
		ways[n] = 1
		for block_length := int(min_block_length); block_length <= n; block_length++ {
			for block_start in 0 .. (n - block_length) {
				ways[n] += ways[n - block_start - block_length - 1]
			}
			ways[n]++
		}
		if ways[n] > 1000000 { return i64(n) }
	}
	return -1
}
