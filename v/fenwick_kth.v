// Fenwick frequency selection by binary lifting over prefix blocks.
module fenwick_kth

@[export: 'fenwick_kth']
pub fn fenwick_kth(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 163 { return -1 }
		nr := input[0]
		qr := input[1]
		if nr < 1 || nr > 64 || qr < 0 || qr > 32 { return -1 }
		n := int(nr)
		q := int(qr)
		if int(length) != 2 + n + 3 * q { return -1 }

		mut frequency := [64]i64{}
		mut tree := [65]i64{}
		mut total := i64(0)
		for i in 0 .. n {
			value := input[2 + i]
			if value < 0 || value > 1_000_000 { return -1 }
			frequency[i] = value
			total += value
			index := i + 1
			tree[index] += value
			parent := index + (index & -index)
			if parent <= n { tree[parent] += tree[index] }
		}

		mut result := i64(0)
		mut query_number := 0
		mut cursor := 2 + n
		for _ in 0 .. q {
			opcode := input[cursor]
			first := input[cursor + 1]
			second := input[cursor + 2]
			cursor += 3
			if opcode == 0 {
				if first < 0 || first >= i64(n) || second < -1_000_000 || second > 1_000_000 { return -1 }
				position := int(first)
				updated := frequency[position] + second
				if updated < 0 || updated > 1_000_000 { return -1 }
				frequency[position] = updated
				total += second
				mut index := position + 1
				for index <= n {
					tree[index] += second
					index += index & -index
				}
			} else if opcode == 1 {
				if second != 0 { return -1 }
				mut answer := i64(-1)
				if first > 0 && first <= total {
					mut index := 0
					mut step := 1
					for step <= n / 2 { step *= 2 }
					mut rank := first
					for step != 0 {
						candidate := index + step
						if candidate <= n && tree[candidate] < rank {
							index = candidate
							rank -= tree[candidate]
						}
						step /= 2
					}
					answer = i64(index)
				}
				result += i64(query_number + 1) * (answer + 1)
				query_number++
			} else {
				return -1
			}
		}
		return result
	}
}
