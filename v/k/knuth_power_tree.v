module knuth_power_tree

const max_target = 127

fn build_path(target int, mut parent [128]int, mut seen [128]bool,
	mut queue [128]int, mut reverse [128]int, mut path [127]int) int {
	if target == 1 { path[0] = 1; return 1 }
	mut head := 0
	mut tail := 1
	queue[0] = 1
	seen[1] = true
	for head < tail {
		current := queue[head]
		head++
		mut chain_length := 0
		mut node := current
		for node != 0 {
			reverse[chain_length] = node
			chain_length++
			node = parent[node]
		}
		for offset in 0 .. chain_length {
			ancestor := reverse[chain_length-offset-1]
			child := current + ancestor
			if child > target || seen[child] { continue }
			seen[child] = true
			parent[child] = current
			if child == target {
				mut count := 0
				node = target
				for node != 0 {
					path[count] = node
					count++
					node = parent[node]
				}
				mut left := 0
				mut right := count - 1
				for left < right {
					path[left], path[right] = path[right], path[left]
					left++
					right--
				}
				return count
			}
			queue[tail] = child
			tail++
		}
	}
	return 0
}

fn store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte] = u8(bits >> (byte * 8)) } }
}

@[export: 'knuth_power_tree']
pub fn knuth_power_tree(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		if input[0] < 1 || input[0] > max_target { return -1 }
		target := int(input[0])
		mut parent := [128]int{}
		mut seen := [128]bool{}
		mut queue := [128]int{}
		mut reverse := [128]int{}
		mut path := [127]int{}
		path_length := build_path(target, mut parent, mut seen, mut queue, mut reverse, mut path)
		if path_length == 0 { return -1 }
		required := usize((path_length + 1) * 8)
		if output == nil || output_capacity < required { return -2 }
		store_i64(mut output, 0, i64(path_length - 1))
		for index in 0 .. path_length { store_i64(mut output, 8 * (index + 1), i64(path[index])) }
		return i64(required)
	}
}
