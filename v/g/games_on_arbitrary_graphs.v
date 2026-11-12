module games_on_arbitrary_graphs

const max_v = 16
const max_e = 32
const max_input = usize(66)
const max_output = 17

@[export: 'games_on_arbitrary_graphs']
pub fn games_on_arbitrary_graphs(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	unsafe {
		nv, me := input[0], input[1]
		if nv < 0 || nv > max_v || me < 0 || me > max_e { return -1 }
		n, m := int(nv), int(me)
		if int(length) != 2 + 2 * m { return -1 }

		mut outmask := [max_v]u16{}
		mut head := [max_v]int{init: -1}
		mut edge_source := [max_e]int{}
		mut edge_next := [max_e]int{init: -1}
		mut remaining := [max_v]int{}
		mut status := [max_v]int{}
		mut queue := [max_v]int{}
		mut staged := [max_output]u8{}
		mut unique_edges := 0
		for i in 0 .. m {
			sv, tv := input[2 + 2 * i], input[3 + 2 * i]
			if sv < 0 || sv >= nv || tv < 0 || tv >= nv { return -1 }
			s, t := int(sv), int(tv)
			bit := u16(1) << t
			if (outmask[s] & bit) == 0 {
				outmask[s] |= bit
				edge_source[unique_edges] = s
				edge_next[unique_edges] = head[t]
				head[t] = unique_edges
				unique_edges++
				remaining[s]++
			}
		}

		mut first, mut count := 0, 0
		for vertex in 0 .. n {
			if remaining[vertex] == 0 {
				status[vertex] = 2
				queue[count] = vertex
				count++
			}
		}
		for first < count {
			resolved := queue[first]
			first++
			edge := head[resolved]
			for edge != -1 {
				predecessor := edge_source[edge]
				if status[predecessor] == 0 {
					if status[resolved] == 2 {
						status[predecessor] = 1
						queue[count] = predecessor
						count++
					} else {
						remaining[predecessor]--
						if remaining[predecessor] == 0 {
							status[predecessor] = 2
							queue[count] = predecessor
							count++
						}
					}
				}
				edge = edge_next[edge]
			}
		}
		staged[0] = u8(n)
		for vertex in 0 .. n { staged[vertex + 1] = u8(status[vertex]) }
		needed := n + 1
		if output == nil || int(capacity) < needed { return -2 }
		for index in 0 .. needed { output[index] = staged[index] }
		return i64(needed)
	}
}
