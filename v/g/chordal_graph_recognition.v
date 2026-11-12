module chordal_graph_recognition

const max_n = 6
const max_input = 32
const max_output = 64

fn put_u64(mut output &u8, index int, value u64) {
	bits := value
	for byte in 0 .. 8 {
		unsafe { output[index * 8 + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'chordal_graph_recognition']
pub fn chordal_graph_recognition(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input || input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > 15 { return -1 }
		n, m := int(input[0]), int(input[1])
		if m > n * (n - 1) / 2 || length != usize(2 + 2 * m) { return -1 }
		mut adjacent := [max_n][max_n]bool{}
		for e in 0 .. m {
			a0, b0 := input[2 + 2 * e], input[3 + 2 * e]
			if a0 < 0 || b0 < 0 || a0 >= i64(n) || b0 >= i64(n) || a0 == b0 { return -1 }
			a, b := int(a0), int(b0)
			if adjacent[a][b] { return -1 }
			adjacent[a][b] = true
			adjacent[b][a] = true
		}
		mut selected := [max_n]bool{}
		mut label := [max_n]int{}
		mut reverse_order := [max_n]int{}
		mut order := [max_n]int{}
		mut position := [max_n]int{}
		for step in 0 .. n {
			mut chosen := -1
			for v in 0 .. n { if !selected[v] && (chosen < 0 || label[v] > label[chosen]) { chosen = v } }
			selected[chosen] = true
			reverse_order[step] = chosen
			for u in 0 .. n { if !selected[u] && adjacent[chosen][u] { label[u]++ } }
		}
		for i in 0 .. n { order[i] = reverse_order[n - i - 1]; position[order[i]] = i }
		mut peo := true
		for i in 0 .. n {
			v := order[i]
			mut parent := -1
			for u in 0 .. n { if adjacent[v][u] && position[u] > i && (parent < 0 || position[u] < position[parent]) { parent = u } }
			if parent >= 0 { for u in 0 .. n { if adjacent[v][u] && position[u] > i && u != parent && !adjacent[parent][u] { peo = false } } }
		}
		mut packed := [8]u64{}
		mut count := 0
		if peo {
			packed[count] = 1
			count++
			for i in 0 .. n { packed[count] = u64(order[i]); count++ }
		} else {
			mut found := false
			mut cycle := [max_n]int{}
			mut cycle_len := 0
			for mask in 0 .. (1 << n) {
				mut vertices := [max_n]int{}
				mut size := 0
				for v in 0 .. n { if (mask & (1 << v)) != 0 { vertices[size] = v; size++ } }
				if size < 4 { continue }
				mut valid := true
				for i in 0 .. size {
					mut degree := 0
					for j in 0 .. size { if adjacent[vertices[i]][vertices[j]] { degree++ } }
					if degree != 2 { valid = false }
				}
				if !valid { continue }
				mut seen := [max_n]bool{}
				mut queue := [max_n]int{}
				mut head := 0
				mut tail := 1
				seen[vertices[0]] = true
				queue[0] = vertices[0]
				for head < tail {
					v := queue[head]
					head++
					for j in 0 .. size { u := vertices[j]; if adjacent[v][u] && !seen[u] { seen[u] = true; queue[tail] = u; tail++ } }
				}
				if tail != size { continue }
				cycle_len = size
				start := vertices[0]
				mut previous := start
				mut current := start
				for j in 0 .. size { if adjacent[start][vertices[j]] { current = vertices[j]; break } }
				cycle[0] = start
				for i in 1 .. size {
					cycle[i] = current
					mut next := start
					for j in 0 .. size { u := vertices[j]; if adjacent[current][u] && u != previous { next = u; break } }
					previous = current
					current = next
				}
				found = true
				break
			}
			if !found { return -1 }
			packed[count] = 0
			count++
			packed[count] = u64(cycle_len)
			count++
			for i in 0 .. cycle_len { packed[count] = u64(cycle[i]); count++ }
		}
		bytes := count * 8
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := [max_output]u8{}
		for i in 0 .. count { put_u64(mut &staged[0], i, packed[i]) }
		for i in 0 .. bytes { output[i] = staged[i] }
		return i64(bytes)
	}
}
