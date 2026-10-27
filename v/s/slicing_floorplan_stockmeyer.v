module slicing_floorplan_stockmeyer

const max_nodes = 15
const max_candidates = 256
const max_input = 32
const output_bytes = 32

struct Candidate {
	height i64
	width i64
	mask u64
}

struct Node {
	op int = -1
	left int
	right int
	count int
	candidates [max_candidates]Candidate
}

fn mask_lex_less(a u64, b u64, leaves int) bool {
	for bit in 0 .. leaves {
		av := (a >> bit) & 1
		bv := (b >> bit) & 1
		if av != bv { return av < bv }
	}
	return false
}

fn prune(mut node Node, leaves int) {
	mut dominated := []bool{len: max_candidates, init: false}
	for i in 0 .. node.count {
		a := node.candidates[i]
		for j in 0 .. node.count {
			if i == j { continue }
			b := node.candidates[j]
			if b.height <= a.height && b.width <= a.width &&
				(b.height < a.height || b.width < a.width || mask_lex_less(b.mask, a.mask, leaves) || (b.mask == a.mask && j < i)) {
				dominated[i] = true
				break
			}
		}
	}
	mut kept := 0
	for i in 0 .. node.count {
		if !dominated[i] { node.candidates[kept] = node.candidates[i]; kept++ }
	}
	node.count = kept
}

fn store_i64_le(value i64, output &u8, offset int) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'slicing_floorplan_stockmeyer']
pub fn slicing_floorplan_stockmeyer(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > 8 { return -1 }
		leaves := int(input[0])
		mut nodes := []Node{len: max_nodes, init: Node{op: -1}}
		mut stack := []int{len: max_nodes, init: 0}
		mut stack_size := 0
		mut node_count := 0
		mut leaf_count := 0
		mut internal_count := 0
		mut position := 1
		for position < int(length) {
			token := input[position]
			position++
			if token == 2 {
				if position + 2 > int(length) || leaf_count >= leaves || node_count >= max_nodes { return -1 }
				height, width := input[position], input[position + 1]
				position += 2
				if height < 1 || height > 20 || width < 1 || width > 20 { return -1 }
				nodes[node_count].op = 2
				nodes[node_count].candidates[0] = Candidate{height: height, width: width, mask: 0}
				nodes[node_count].candidates[1] = Candidate{height: width, width: height, mask: u64(1) << leaf_count}
				nodes[node_count].count = 2
				prune(mut nodes[node_count], leaves)
				stack[stack_size] = node_count
				stack_size++
				node_count++
				leaf_count++
			} else if token == 0 || token == 1 {
				if stack_size < 2 || internal_count >= leaves - 1 || node_count >= max_nodes { return -1 }
				stack_size--
				right := stack[stack_size]
				stack_size--
				left := stack[stack_size]
				if nodes[right].op == int(token) { return -1 }
				nodes[node_count].op = int(token)
				nodes[node_count].left = left
				nodes[node_count].right = right
				for i in 0 .. nodes[left].count {
					for j in 0 .. nodes[right].count {
						if nodes[node_count].count >= max_candidates { return -1 }
						a, b := nodes[left].candidates[i], nodes[right].candidates[j]
						mut c := Candidate{mask: a.mask | b.mask}
						if token == 0 {
							c.height = if a.height > b.height { a.height } else { b.height }
							c.width = a.width + b.width
						} else {
							c.height = a.height + b.height
							c.width = if a.width > b.width { a.width } else { b.width }
						}
						nodes[node_count].candidates[nodes[node_count].count] = c
						nodes[node_count].count++
					}
				}
				prune(mut nodes[node_count], leaves)
				stack[stack_size] = node_count
				stack_size++
				node_count++
				internal_count++
			} else { return -1 }
		}
		if position != int(length) || leaf_count != leaves || internal_count != leaves - 1 || node_count != 2 * leaves - 1 || stack_size != 1 { return -1 }
		root := nodes[stack[0]]
		if root.count == 0 { return -1 }
		mut best := root.candidates[0]
		for i in 1 .. root.count {
			candidate := root.candidates[i]
			area, best_area := candidate.height * candidate.width, best.height * best.width
			if area < best_area || (area == best_area && (candidate.height < best.height ||
				(candidate.height == best.height && (candidate.width < best.width ||
				(candidate.width == best.width && mask_lex_less(candidate.mask, best.mask, leaves))))) { best = candidate }
		}
		if output == nil || capacity < output_bytes { return -2 }
		mut staged := [output_bytes]u8{}
		store_i64_le(best.height * best.width, &staged[0], 0)
		store_i64_le(best.height, &staged[0], 8)
		store_i64_le(best.width, &staged[0], 16)
		store_i64_le(i64(best.mask), &staged[0], 24)
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return output_bytes
	}
}
