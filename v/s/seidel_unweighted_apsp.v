module seidel_unweighted_apsp

fn distances(adjacency [64]i64, n int) [64]i64 {
	mut squared := [64]i64{}
	mut expanded := [64]i64{}
	mut result := [64]i64{}
	mut degree := [8]i64{}
	mut complete := true
	for i in 0 .. n {
		for j in 0 .. n {
			degree[i] += adjacency[8 * i + j]
			if i != j && adjacency[8 * i + j] == 0 { complete = false }
			for k in 0 .. n { squared[8 * i + j] += adjacency[8 * i + k] * adjacency[8 * k + j] }
		}
	}
	if complete {
		for i in 0 .. n { for j in 0 .. n { if i != j { result[8 * i + j] = 1 } } }
		return result
	}
	for i in 0 .. n {
		for j in 0 .. n {
			if i != j && (adjacency[8 * i + j] != 0 || squared[8 * i + j] != 0) { expanded[8 * i + j] = 1 }
		}
	}
	coarse := distances(expanded, n)
	for i in 0 .. n {
		for j in 0 .. n {
			if i == j { continue }
			mut neighbor_sum := i64(0)
			for k in 0 .. n { neighbor_sum += coarse[8 * i + k] * adjacency[8 * k + j] }
			result[8 * i + j] = 2 * coarse[8 * i + j]
			if neighbor_sum < coarse[8 * i + j] * degree[j] { result[8 * i + j]-- }
		}
	}
	return result
}

@[export: 'seidel_unweighted_apsp']
pub fn seidel_unweighted_apsp(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 66 { return -1 }
		if input[0] < 1 || input[0] > 8 { return -1 }
		n := int(input[0])
		if length != usize(1 + n * n) { return -1 }
		mut adjacency := [64]i64{}
		for i in 0 .. n {
			for j in 0 .. n {
				value := input[1 + i * n + j]
				if value < 0 || value > 1 || (i == j && value != 0) { return -1 }
				adjacency[8 * i + j] = value
			}
		}
		for i in 0 .. n { for j in 0 .. i { if adjacency[8 * i + j] != adjacency[8 * j + i] { return -1 } } }
		mut seen := [8]bool{}
		mut queue := [8]int{}
		seen[0] = true
		mut head := 0
		mut tail := 1
		for head < tail {
			vertex := queue[head]
			head++
			for other in 0 .. n {
				if adjacency[8 * vertex + other] != 0 && !seen[other] {
					seen[other] = true
					queue[tail] = other
					tail++
				}
			}
		}
		if tail != n { return -1 }
		bytes := 8 * n * n
		if output == nil || capacity < usize(bytes) { return -2 }
		result := distances(adjacency, n)
		for i in 0 .. n {
			for j in 0 .. n {
				mut bits := u64(result[8 * i + j])
				for byte in 0 .. 8 {
					output[8 * (i * n + j) + byte] = u8(bits & 255)
					bits >>= 8
				}
			}
		}
		return i64(bytes)
	}
}
