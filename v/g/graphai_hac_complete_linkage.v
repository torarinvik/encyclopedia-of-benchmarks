// Clean-room bounded GraphAIBench complete-linkage HAC; see package LICENSE.txt.
@[export: 'graphai_hac_complete_linkage']
pub fn graphai_hac_complete_linkage(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 74 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 8 || m64 < 0 || m64 > 24 || length != usize(2 + 3*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacent := [][]int{len: 8, init: []int{len: 8, init: 0}}
		mut used_weight := []bool{len: 33, init: false}
		for edge in 0 .. m {
			u64 := input[2+3*edge]
			v64 := input[3+3*edge]
			w64 := input[4+3*edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 || w64 < 1 || w64 > 32 { return -1 }
			u := int(u64)
			v := int(v64)
			w := int(w64)
			if adjacent[u][v] != 0 || used_weight[w] { return -1 }
			adjacent[u][v] = w
			adjacent[v][u] = w
			used_weight[w] = true
		}
		mut reached := []bool{len: 8, init: false}
		mut queue := []int{len: 8, init: 0}
		reached[0] = true
		mut head := 0
		mut tail := 1
		for head < tail {
			u := queue[head]
			head++
			for v in 0 .. n {
				if adjacent[u][v] != 0 && !reached[v] { reached[v] = true; queue[tail] = v; tail++ }
			}
		}
		for v in 0 .. n { if !reached[v] { return -1 } }
		node_count := 2*n-1
		output_bytes := 16*node_count
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut active := []bool{len: 8, init: false}
		mut current_id := []int{len: 8, init: 0}
		mut parent := []i64{len: 15, init: 4294967295}
		mut merge_weight := []i64{len: 15, init: 0}
		for u in 0 .. n { active[u] = true; current_id[u] = u }
		for merge in 0 .. n-1 {
			mut best_u := -1
			mut best_v := -1
			mut best_weight := 0
			for u in 0 .. n {
				if active[u] {
					for v in u+1 .. n {
						if active[v] && adjacent[u][v] > best_weight { best_u = u; best_v = v; best_weight = adjacent[u][v] }
					}
				}
			}
			if best_u < 0 { return -1 }
			mut degree_u := 0
			mut degree_v := 0
			for z in 0 .. n {
				if active[z] && adjacent[best_u][z] != 0 { degree_u++ }
				if active[z] && adjacent[best_v][z] != 0 { degree_v++ }
			}
			larger := if degree_u < degree_v { best_v } else { best_u }
			smaller := if larger == best_u { best_v } else { best_u }
			new_id := n+merge
			parent[current_id[best_u]] = i64(new_id)
			parent[current_id[best_v]] = i64(new_id)
			merge_weight[current_id[best_u]] = i64(best_weight)
			merge_weight[current_id[best_v]] = i64(best_weight)
			mut merged_weight := []int{len: 8, init: 0}
			for z in 0 .. n {
				if active[z] && z != best_u && z != best_v {
					a := adjacent[best_u][z]
					b := adjacent[best_v][z]
					if a != 0 || b != 0 { merged_weight[z] = if a != 0 && b != 0 { min(a,b) } else if a != 0 { a } else { b } }
				}
			}
			for z in 0 .. n { adjacent[best_u][z] = 0; adjacent[z][best_u] = 0; adjacent[best_v][z] = 0; adjacent[z][best_v] = 0 }
			active[smaller] = false
			for z in 0 .. n { if active[z] && z != larger && merged_weight[z] != 0 { adjacent[larger][z] = merged_weight[z]; adjacent[z][larger] = merged_weight[z] } }
			current_id[larger] = new_id
		}
		for node in 0 .. node_count {
			for slot, value in [parent[node], merge_weight[node]] {
				bits := u64(value)
				for byte in 0 .. 8 { output[16*node+8*slot+byte] = u8((bits >> (8*byte)) & 255) }
			}
		}
		return i64(output_bytes)
	}
}
