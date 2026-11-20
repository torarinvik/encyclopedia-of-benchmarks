// Bounded clean-room connected/co-connected cograph cotree profile.
const max_n = 12
const max_m = 66
const max_parseable = 135
const max_output = 47

fn ct_components(mask u16, adjacency []u16, complement bool) []u16 {
	mut remaining := mask
	mut parts := []u16{}
	for root in 0 .. max_n {
		root_bit := u16(1) << root
		if remaining & root_bit == 0 { continue }
		mut reached := root_bit
		mut queue := []int{cap: max_n}
		queue << root
		mut head := 0
		for head < queue.len {
			vertex := queue[head]
			head++
			mut neighbors := adjacency[vertex] & mask
			if complement { neighbors = mask & ~adjacency[vertex] & ~(u16(1) << vertex) }
			mut fresh := neighbors & ~reached
			for next in 0 .. max_n {
				bit := u16(1) << next
				if fresh & bit != 0 {
					fresh &= ~bit
					reached |= bit
					queue << next
				}
			}
		}
		parts << reached
		remaining &= ~reached
	}
	return parts
}

fn ct_emit(mask u16, adjacency []u16, mut output []u8, mut position int) bool {
	if mask & (mask - 1) == 0 {
		mut vertex := 0
		for mask & (u16(1) << vertex) == 0 { vertex++ }
		output[position] = 0
		output[position + 1] = u8(vertex)
		position += 2
		return true
	}
	mut parts := ct_components(mask, adjacency, false)
	mut kind := u8(1)
	if parts.len == 1 {
		parts = ct_components(mask, adjacency, true)
		kind = 2
		if parts.len <= 1 { return false }
	}
	output[position] = kind
	output[position + 1] = u8(parts.len)
	position += 2
	for child in parts {
		if !ct_emit(child, adjacency, mut output, mut position) { return false }
	}
	return true
}

@[export: 'cograph_cotree_decomposition']
pub fn cograph_cotree_decomposition(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m || m64 > n64 * (n64 - 1) / 2 || length != usize(2 + 2*m64) { return -1 }
		n, m := int(n64), int(m64)
		mut adjacency := []u16{len: max_n}
		for edge in 0 .. m {
			u64, v64 := input[2 + 2*edge], input[3 + 2*edge]
			if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64 { return -1 }
			u, v := int(u64), int(v64)
			ub, vb := u16(1) << u, u16(1) << v
			if adjacency[u] & vb != 0 { return -1 }
			adjacency[u] |= vb
			adjacency[v] |= ub
		}
		mut staged := []u8{len: max_output}
		mut position := 1
		if ct_emit((u16(1) << n) - 1, adjacency, mut staged, mut position) { staged[0] = 1 }
		else { staged[0] = 0; position = 1 }
		if output == nil || capacity < usize(position) { return -2 }
		for i in 0 .. position { output[i] = staged[i] }
		return i64(position)
	}
}
