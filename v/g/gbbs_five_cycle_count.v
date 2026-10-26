// Clean-room bounded GBBS five-cycle profile; see package LICENSE.txt.
@[export: 'gbbs_five_cycle_count']
pub fn gbbs_five_cycle_count(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 130 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2+2*m) { return -1 }
		mut adjacent := [][]bool{len: 16, init: []bool{len: 16, init: false}}
		for edge in 0 .. m {
			u64 := input[2+2*edge]
			v64 := input[3+2*edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return -1 }
			adjacent[u][v] = true
			adjacent[v][u] = true
		}
		if output == nil || capacity < 8 { return -2 }
		mut count := i64(0)
		for start in 0 .. n {
			for first in start+1 .. n {
				for second in start+1 .. n {
					if second == first { continue }
					for third in start+1 .. n {
						if third == first || third == second { continue }
						for last in first+1 .. n {
							if last == second || last == third { continue }
							if adjacent[start][first] && adjacent[first][second] && adjacent[second][third] && adjacent[third][last] && adjacent[last][start] { count++ }
						}
					}
				}
			}
		}
		bits := u64(count)
		for byte in 0 .. 8 { output[byte] = u8((bits >> (8*byte)) & 255) }
		return 8
	}
}
