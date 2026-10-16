package undirected_graph

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 28
MAX_OPERATIONS :: 128
MAX_INPUT_LENGTH :: 599
MIN_WEIGHT :: i64(-1_000_000)
MAX_WEIGHT :: i64(1_000_000)
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)
RESULT_MASK :: u64(0x7fffffffffffffff)

hash_byte :: proc(hash: u64, value: u8) -> u64 {
	return (hash ^ u64(value)) * FNV_PRIME
}

hash_i32 :: proc(hash_value: u64, value: i64) -> u64 {
	hash := hash_value
	bits := u32(value)
	for shift := 0; shift < 32; shift += 8 { hash = hash_byte(hash, u8(bits >> shift)) }
	return hash
}

hash_u32 :: proc(hash_value: u64, value: u32) -> u64 {
	hash := hash_value
	for shift := 0; shift < 32; shift += 8 { hash = hash_byte(hash, u8(value >> shift)) }
	return hash
}

edge_bit_index :: proc(n: int, u_input: int, v_input: int) -> int {
	u, v := u_input, v_input
	if u > v { u, v = v, u }
	index := 0
	for first := 0; first < u; first += 1 { index += n - first - 1 }
	return index + v - u - 1
}

component_count :: proc(n: int, present: [^]u8) -> int {
	seen: [MAX_VERTICES]bool = {}
	count := 0
	for root := 0; root < n; root += 1 {
		if seen[root] { continue }
		count += 1
		stack: [MAX_VERTICES]int
		size := 1
		seen[root] = true
		stack[0] = root
		for size > 0 {
			size -= 1
			node := stack[size]
			for neighbor := 0; neighbor < n; neighbor += 1 {
				if present[node * MAX_VERTICES + neighbor] != 0 && !seen[neighbor] {
					seen[neighbor] = true
					stack[size] = neighbor
					size += 1
				}
			}
		}
	}
	return count
}

prim_forest :: proc(n: int, present: [^]u8, weights: [^]i64, component_total: ^int, edge_mask: ^u32) {
	in_forest: [MAX_VERTICES]bool = {}
	best_weight: [MAX_VERTICES]i64 = {}
	best_parent: [MAX_VERTICES]int
	for i := 0; i < MAX_VERTICES; i += 1 { best_parent[i] = -1 }
	component_total^ = 0
	edge_mask^ = 0
	for root := 0; root < n; root += 1 {
		if in_forest[root] { continue }
		component_total^ += 1
		in_forest[root] = true
		for neighbor := 0; neighbor < n; neighbor += 1 {
			index := root * MAX_VERTICES + neighbor
			if present[index] != 0 && !in_forest[neighbor] {
				best_weight[neighbor] = weights[index]
				best_parent[neighbor] = root
			}
		}
		for {
			selected := -1
			for candidate := 0; candidate < n; candidate += 1 {
				if in_forest[candidate] || best_parent[candidate] < 0 { continue }
				if selected < 0 || best_weight[candidate] < best_weight[selected] { selected = candidate }
			}
			if selected < 0 { break }
			parent := best_parent[selected]
			edge_mask^ |= u32(1) << u32(edge_bit_index(n, parent, selected))
			in_forest[selected] = true
			best_parent[selected] = -1
			for neighbor := 0; neighbor < n; neighbor += 1 {
				index := selected * MAX_VERTICES + neighbor
				if present[index] != 0 && !in_forest[neighbor] &&
					(best_parent[neighbor] < 0 || weights[index] < best_weight[neighbor]) {
					best_weight[neighbor] = weights[index]
					best_parent[neighbor] = selected
				}
			}
		}
	}
}

find_root :: proc(parent: [^]int, node_input: int) -> int {
	node := node_input
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

kruskal_forest :: proc(n: int, present: [^]u8, weights: [^]i64,
	component_total: ^int, edge_mask: ^u32) {
	edge_u: [MAX_EDGES]int
	edge_v: [MAX_EDGES]int
	edge_weight: [MAX_EDGES]i64
	edge_count := 0
	for u := 0; u < n; u += 1 {
		for v := u + 1; v < n; v += 1 {
			index := u * MAX_VERTICES + v
			if present[index] != 0 {
				edge_u[edge_count] = u
				edge_v[edge_count] = v
				edge_weight[edge_count] = weights[index]
				edge_count += 1
			}
		}
	}
	for i := 1; i < edge_count; i += 1 {
		u, v, weight := edge_u[i], edge_v[i], edge_weight[i]
		j := i
		for j > 0 && edge_weight[j - 1] > weight {
			edge_u[j] = edge_u[j - 1]
			edge_v[j] = edge_v[j - 1]
			edge_weight[j] = edge_weight[j - 1]
			j -= 1
		}
		edge_u[j], edge_v[j], edge_weight[j] = u, v, weight
	}
	parent: [MAX_VERTICES]int
	rank: [MAX_VERTICES]int = {}
	for i := 0; i < n; i += 1 { parent[i] = i }
	component_total^ = n
	edge_mask^ = 0
	for i := 0; i < edge_count; i += 1 {
		left := find_root(&parent[0], edge_u[i])
		right := find_root(&parent[0], edge_v[i])
		if left == right { continue }
		if rank[left] < rank[right] { parent[left] = right }
		else if rank[left] > rank[right] { parent[right] = left }
		else { parent[right] = left; rank[left] += 1 }
		component_total^ -= 1
		edge_mask^ |= u32(1) << u32(edge_bit_index(n, edge_u[i], edge_v[i]))
	}
}

@(export)
undirected_graph :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_value, initial_count_value := input[0], input[1]
	if n_value < 0 || n_value > MAX_VERTICES || initial_count_value < 0 || initial_count_value > MAX_EDGES do return -1
	n, initial_count := int(n_value), int(initial_count_value)
	if initial_count > n * (n - 1) / 2 do return -1
	count_position := 2 + 3 * initial_count
	if c.size_t(count_position) >= length do return -1
	operation_count_value := input[count_position]
	if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS ||
		length != c.size_t(3 + 3 * initial_count + 4 * operation_count_value) do return -1

	present: [64]u8 = {}
	weights: [64]i64 = {}
	for edge := 0; edge < initial_count; edge += 1 {
		position := 2 + 3 * edge
		u_value, v_value, weight := input[position], input[position + 1], input[position + 2]
		if u_value < 0 || u_value >= v_value || v_value >= n_value || weight < MIN_WEIGHT || weight > MAX_WEIGHT do return -1
		u, v := int(u_value), int(v_value)
		if present[u * MAX_VERTICES + v] != 0 do return -1
		for first := 0; first < n; first += 1 {
			for second := first + 1; second < n; second += 1 {
				index := first * MAX_VERTICES + second
				if present[index] != 0 && weights[index] == weight do return -1
			}
		}
		present[u * MAX_VERTICES + v] = 1; present[v * MAX_VERTICES + u] = 1
		weights[u * MAX_VERTICES + v] = weight; weights[v * MAX_VERTICES + u] = weight
	}

	hash := FNV_OFFSET
	for operation := 0; operation < int(operation_count_value); operation += 1 {
		position := count_position + 1 + 4 * operation
		opcode, u_value, v_value, weight := input[position], input[position + 1], input[position + 2], input[position + 3]
		result_code := u8(0)
		if opcode == 0 {
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value || weight < MIN_WEIGHT || weight > MAX_WEIGHT do return -1
			u, v := int(u_value), int(v_value)
			index, reverse := u * MAX_VERTICES + v, v * MAX_VERTICES + u
			old_index := if u < v then index else reverse
			for first := 0; first < n; first += 1 {
				for second := first + 1; second < n; second += 1 {
					other := first * MAX_VERTICES + second
					if other != old_index && present[other] != 0 && weights[other] == weight do return -1
				}
			}
			present[index] = 1; present[reverse] = 1; weights[index] = weight; weights[reverse] = weight
		} else if opcode == 1 || opcode == 2 {
			if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value || weight != 0 do return -1
			u, v := int(u_value), int(v_value)
			index, reverse := u * MAX_VERTICES + v, v * MAX_VERTICES + u
			if opcode == 1 { present[index] = 0; present[reverse] = 0; weights[index] = 0; weights[reverse] = 0 }
			else { result_code = present[index] }
		} else if opcode == 3 {
			if u_value != 0 || v_value != 0 || weight != 0 do return -1
			hash = hash_byte(hash, u8(opcode)); hash = hash_byte(hash, result_code)
			hash = hash_byte(hash, u8(component_count(n, &present[0])))
			continue
		} else if opcode == 4 || opcode == 5 || opcode == 6 {
			if u_value != 0 || v_value != 0 || weight != 0 do return -1
			components: int
			mask: u32
			if opcode == 5 { kruskal_forest(n, &present[0], &weights[0], &components, &mask) }
			else { prim_forest(n, &present[0], &weights[0], &components, &mask) }
			hash = hash_byte(hash, u8(opcode)); hash = hash_byte(hash, result_code)
			hash = hash_byte(hash, u8(components)); hash = hash_u32(hash, mask)
			continue
		} else { return -1 }
		hash = hash_byte(hash, u8(opcode)); hash = hash_byte(hash, result_code)
	}

	active_count := 0
	for u := 0; u < n; u += 1 { for v := u + 1; v < n; v += 1 { if present[u * MAX_VERTICES + v] != 0 { active_count += 1 } } }
	hash = hash_byte(hash, u8(n)); hash = hash_byte(hash, u8(active_count))
	for u := 0; u < n; u += 1 {
		for v := u + 1; v < n; v += 1 {
			index := u * MAX_VERTICES + v
			if present[index] == 0 { continue }
			hash = hash_byte(hash, u8(u)); hash = hash_byte(hash, u8(v)); hash = hash_i32(hash, weights[index])
		}
	}
	return i64(hash & RESULT_MASK)
}
