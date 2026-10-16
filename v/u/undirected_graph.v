module undirected_graph

const max_vertices = 8
const max_edges = 28
const max_operations = 128
const max_input_length = 599
const min_weight = i64(-1000000)
const max_weight = i64(1000000)
const fnv_offset = u64(0xcbf29ce484222325)
const fnv_prime = u64(0x100000001b3)
const result_mask = u64(0x7fffffffffffffff)

fn hash_byte(hash u64, value u8) u64 {
	return (hash ^ u64(value)) * fnv_prime
}

fn hash_i32(hash_value u64, value i64) u64 {
	mut hash := hash_value
	bits := u32(i32(value))
	for shift in 0 .. 4 {
		hash = hash_byte(hash, u8((bits >> (shift * 8)) & 255))
	}
	return hash
}

fn hash_u32(hash_value u64, value u32) u64 {
	mut hash := hash_value
	for shift in 0 .. 4 {
		hash = hash_byte(hash, u8((value >> (shift * 8)) & 255))
	}
	return hash
}

fn edge_bit_index(n int, u_input int, v_input int) int {
	mut u := u_input
	mut v := v_input
	if u > v {
		temp := u
		u = v
		v = temp
	}
	mut index := 0
	for first in 0 .. u {
		index += n - first - 1
	}
	return index + v - u - 1
}

fn component_count(n int, present [64]u8) int {
	mut seen := [8]bool{}
	mut count := 0
	for root in 0 .. n {
		if seen[root] {
			continue
		}
		count++
		seen[root] = true
		mut stack := [8]int{}
		mut size := 1
		stack[0] = root
		for size > 0 {
			size--
			node := stack[size]
			for neighbor in 0 .. n {
				if present[node * max_vertices + neighbor] != 0 && !seen[neighbor] {
					seen[neighbor] = true
					stack[size] = neighbor
					size++
				}
			}
		}
	}
	return count
}

struct Forest {
	components int
	edge_mask  u32
}

fn prim_forest(n int, present [64]u8, weights [64]i64) Forest {
	mut in_forest := [8]bool{}
	mut best_weight := [8]i64{}
	mut best_parent := [8]int{init: -1}
	mut components := 0
	mut edge_mask := u32(0)
	for root in 0 .. n {
		if in_forest[root] {
			continue
		}
		components++
		in_forest[root] = true
		for neighbor in 0 .. n {
			index := root * max_vertices + neighbor
			if present[index] != 0 && !in_forest[neighbor] {
				best_weight[neighbor] = weights[index]
				best_parent[neighbor] = root
			}
		}
		for {
			mut selected := -1
			for candidate in 0 .. n {
				if in_forest[candidate] || best_parent[candidate] < 0 {
					continue
				}
				if selected < 0 || best_weight[candidate] < best_weight[selected] {
					selected = candidate
				}
			}
			if selected < 0 {
				break
			}
			parent := best_parent[selected]
			edge_mask |= u32(1) << edge_bit_index(n, parent, selected)
			in_forest[selected] = true
			best_parent[selected] = -1
			for neighbor in 0 .. n {
				index := selected * max_vertices + neighbor
				if present[index] != 0 && !in_forest[neighbor] &&
					(best_parent[neighbor] < 0 || weights[index] < best_weight[neighbor]) {
					best_weight[neighbor] = weights[index]
					best_parent[neighbor] = selected
				}
			}
		}
	}
	return Forest{components, edge_mask}
}

fn find_root(mut parent [8]int, node_input int) int {
	mut node := node_input
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn kruskal_forest(n int, present [64]u8, weights [64]i64) Forest {
	mut edge_u := [28]int{}
	mut edge_v := [28]int{}
	mut edge_weight := [28]i64{}
	mut edge_count := 0
	for u in 0 .. n {
		for v in u + 1 .. n {
			index := u * max_vertices + v
			if present[index] == 0 {
				continue
			}
		edge_u[edge_count] = u
			edge_v[edge_count] = v
			edge_weight[edge_count] = weights[index]
			edge_count++
		}
	}
	for i in 1 .. edge_count {
		u := edge_u[i]
		v := edge_v[i]
		weight := edge_weight[i]
		mut j := i
		for j > 0 && edge_weight[j - 1] > weight {
			edge_u[j] = edge_u[j - 1]
			edge_v[j] = edge_v[j - 1]
			edge_weight[j] = edge_weight[j - 1]
			j--
		}
		edge_u[j] = u
		edge_v[j] = v
		edge_weight[j] = weight
	}
	mut parent := [8]int{}
	mut rank := [8]int{}
	for index in 0 .. n {
		parent[index] = index
	}
	mut components := n
	mut edge_mask := u32(0)
	for i in 0 .. edge_count {
		left := find_root(mut parent, edge_u[i])
		right := find_root(mut parent, edge_v[i])
		if left == right {
			continue
		}
		if rank[left] < rank[right] {
			parent[left] = right
		} else if rank[left] > rank[right] {
			parent[right] = left
		} else {
			parent[right] = left
			rank[left]++
		}
		components--
		edge_mask |= u32(1) << edge_bit_index(n, edge_u[i], edge_v[i])
	}
	return Forest{components, edge_mask}
}

@[export: 'undirected_graph']
pub fn undirected_graph(input &i64, length usize) i64 {
	if unsafe { isnil(input) } || length < 3 || length > max_input_length {
		return -1
	}
	unsafe {
		n_value := input[0]
		initial_count_value := input[1]
		if n_value < 0 || n_value > max_vertices || initial_count_value < 0 || initial_count_value > max_edges {
			return -1
		}
		n := int(n_value)
		initial_count := int(initial_count_value)
		if initial_count > n * (n - 1) / 2 {
			return -1
		}
		count_position := 2 + 3 * initial_count
		if count_position >= int(length) {
			return -1
		}
		operation_count_value := input[count_position]
		if operation_count_value < 0 || operation_count_value > max_operations ||
			int(length) != 3 + 3 * initial_count + 4 * int(operation_count_value) {
			return -1
		}

		mut present := [64]u8{}
		mut weights := [64]i64{}
		for edge in 0 .. initial_count {
			position := 2 + 3 * edge
			u_value := input[position]
			v_value := input[position + 1]
			weight := input[position + 2]
			if u_value < 0 || u_value >= v_value || v_value >= n_value || weight < min_weight || weight > max_weight {
				return -1
			}
			u := int(u_value)
			v := int(v_value)
			if present[u * max_vertices + v] != 0 {
				return -1
			}
			for first in 0 .. n {
				for second in first + 1 .. n {
					index := first * max_vertices + second
					if present[index] != 0 && weights[index] == weight {
						return -1
					}
				}
			}
			present[u * max_vertices + v] = 1
			present[v * max_vertices + u] = 1
			weights[u * max_vertices + v] = weight
			weights[v * max_vertices + u] = weight
		}

		mut hash := fnv_offset
		for operation in 0 .. int(operation_count_value) {
			position := count_position + 1 + 4 * operation
			opcode := input[position]
			u_value := input[position + 1]
			v_value := input[position + 2]
			weight := input[position + 3]
			mut result_code := u8(0)
			if opcode == 0 {
				if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value ||
					weight < min_weight || weight > max_weight {
					return -1
				}
				u := int(u_value)
				v := int(v_value)
				index := u * max_vertices + v
				reverse := v * max_vertices + u
				old_index := if u < v { index } else { reverse }
				for first in 0 .. n {
					for second in first + 1 .. n {
						other := first * max_vertices + second
						if other != old_index && present[other] != 0 && weights[other] == weight {
							return -1
						}
					}
				}
				present[index] = 1
				present[reverse] = 1
				weights[index] = weight
				weights[reverse] = weight
			} else if opcode == 1 || opcode == 2 {
				if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value || weight != 0 {
					return -1
				}
				u := int(u_value)
				v := int(v_value)
				index := u * max_vertices + v
				reverse := v * max_vertices + u
				if opcode == 1 {
					present[index] = 0
					present[reverse] = 0
					weights[index] = 0
					weights[reverse] = 0
				} else {
					result_code = present[index]
				}
			} else if opcode == 3 {
				if u_value != 0 || v_value != 0 || weight != 0 {
					return -1
				}
				hash = hash_byte(hash, u8(opcode))
				hash = hash_byte(hash, result_code)
				hash = hash_byte(hash, u8(component_count(n, present)))
				continue
			} else if opcode == 4 || opcode == 5 || opcode == 6 {
				if u_value != 0 || v_value != 0 || weight != 0 {
					return -1
				}
				forest := if opcode == 5 { kruskal_forest(n, present, weights) } else { prim_forest(n, present, weights) }
				hash = hash_byte(hash, u8(opcode))
				hash = hash_byte(hash, result_code)
				hash = hash_byte(hash, u8(forest.components))
				hash = hash_u32(hash, forest.edge_mask)
				continue
			} else {
				return -1
			}
			hash = hash_byte(hash, u8(opcode))
			hash = hash_byte(hash, result_code)
		}

		mut active_count := 0
		for u in 0 .. n {
			for v in u + 1 .. n {
				if present[u * max_vertices + v] != 0 {
					active_count++
				}
			}
		}
		hash = hash_byte(hash, u8(n))
		hash = hash_byte(hash, u8(active_count))
		for u in 0 .. n {
			for v in u + 1 .. n {
				index := u * max_vertices + v
				if present[index] == 0 {
					continue
				}
				hash = hash_byte(hash, u8(u))
				hash = hash_byte(hash, u8(v))
				hash = hash_i32(hash, weights[index])
			}
		}
		return i64(hash & result_mask)
	}
}
