fn bip_find(mut parent [32]i64, mut parity [32]i64, start int) [2]i64 {
	mut root := start
	mut total := i64(0)
	for int(parent[root]) != root { total ^= parity[root]; root = int(parent[root]) }
	mut node := start
	mut accumulated := i64(0)
	for int(parent[node]) != node {
		next := int(parent[node])
		edge := parity[node]
		parent[node] = i64(root)
		parity[node] = total ^ accumulated
		accumulated ^= edge
		node = next
	}
	return [i64(root), total]
}

@[export: 'online_bipartiteness_dsu']
pub fn online_bipartiteness_dsu(input &i64, length usize) i64 {
	if length < 2 || length > 195 { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > 32 || q_value < 0 || q_value > 64 { return -1 }
		n, q := int(n_value), int(q_value)
		if length != usize(2 + 3*q) { return -1 }
		for j in 0 .. q {
			opcode, a, b := input[2+3*j], input[3+3*j], input[4+3*j]
			if opcode == 0 {
				if a < 0 || a >= n_value || b < 0 || b >= n_value { return -1 }
			} else if opcode == 1 {
				if a < 0 || a >= n_value || b != 0 { return -1 }
			} else { return -1 }
		}
		mut parent := [32]i64{}
		mut size := [32]i64{}
		mut parity := [32]i64{}
		mut bad := [32]i64{}
		for i in 0 .. n { parent[i] = i64(i); size[i] = 1 }
		mut checksum := i64(0)
		mut query_ordinal := i64(0)
		for j in 0 .. q {
			opcode := input[2+3*j]
			a := int(input[3+3*j])
			if opcode == 1 {
				found := bip_find(mut parent, mut parity, a)
				answer := i64(1)
				if bad[int(found[0])] != 0 { answer = 0 }
				checksum += (query_ordinal+1) * (answer+1)
				query_ordinal++
				continue
			}
			b := int(input[4+3*j])
			found_a := bip_find(mut parent, mut parity, a)
			found_b := bip_find(mut parent, mut parity, b)
			mut root_a, mut root_b := int(found_a[0]), int(found_b[0])
			mut parity_a, mut parity_b := found_a[1], found_b[1]
			if root_a == root_b {
				if parity_a == parity_b { bad[root_a] = 1 }
				continue
			}
			if size[root_a] < size[root_b] {
				root_a, root_b = root_b, root_a
				parity_a, parity_b = parity_b, parity_a
			}
			parent[root_b] = i64(root_a)
			parity[root_b] = parity_a ^ parity_b ^ 1
			size[root_a] += size[root_b]
			if bad[root_b] != 0 { bad[root_a] = 1 }
		}
		return checksum
	}
}
