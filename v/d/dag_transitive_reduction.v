module dag_transitive_reduction

const max_n = 8
const max_m = 28
const max_length = 58

@[export: 'dag_transitive_reduction']
pub fn dag_transitive_reduction(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_length + 1 { return -1 }
		if input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_m { return -1 }
		n := int(input[0])
		m := int(input[1])
		if length != usize(2 + 2*m) { return -1 }

		mut outgoing := [max_n]int{}
		for edge in 0 .. m {
			tail_value := input[2 + 2*edge]
			head_value := input[3 + 2*edge]
			if tail_value < 0 || head_value < 0 || tail_value >= i64(n) || head_value >= i64(n) || tail_value == head_value { return -1 }
			tail := int(tail_value)
			head := int(head_value)
			bit := 1 << head
			if (outgoing[tail] & bit) != 0 { return -1 }
			outgoing[tail] |= bit
		}

		mut reach := [max_n]int{}
		for vertex in 0 .. n { reach[vertex] = outgoing[vertex] }
		for middle in 0 .. n {
			for source in 0 .. n {
				if (reach[source] & (1 << middle)) != 0 {
					reach[source] |= reach[middle]
				}
			}
		}
		for vertex in 0 .. n { if (reach[vertex] & (1 << vertex)) != 0 { return -1 } }

		mut retained := i64(0)
		for edge in 0 .. m {
			tail := int(input[2 + 2*edge])
			head := int(input[3 + 2*edge])
			mut redundant := false
			for middle in 0 .. n {
				if middle != tail && middle != head &&
					(outgoing[tail] & (1 << middle)) != 0 && (reach[middle] & (1 << head)) != 0 {
					redundant = true
				}
			}
			if !redundant { retained += 1 }
		}
		return retained
	}
}
