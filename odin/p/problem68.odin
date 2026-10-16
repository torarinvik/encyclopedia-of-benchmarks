package problem68

value_at :: proc(values: [10]i64, indices: [10]i64, position: int) -> i64 {
	return values[indices[position]]
}

next_permutation :: proc(indices: ^[10]i64, length: int) -> bool {
	pivot := length - 2
	for pivot >= 0 && indices[pivot] >= indices[pivot + 1] { pivot -= 1 }
	if pivot < 0 do return false
	successor := length - 1
	for indices[successor] <= indices[pivot] { successor -= 1 }
	temporary := indices[pivot]
	indices[pivot] = indices[successor]
	indices[successor] = temporary
	left := pivot + 1
	right := length - 1
	for left < right {
		temporary = indices[left]; indices[left] = indices[right]; indices[right] = temporary
		left += 1; right -= 1
	}
	return true
}

@(export)
problem68 :: proc "c" (gon_side: i64) -> i64 {
	if gon_side < 3 || gon_side > 5 do return -1
	n := int(gon_side)
	length := 2 * n
	values: [10]i64
	cursor := 0
	for value := n + 1; value >= 1; value -= 1 { values[cursor] = i64(value); cursor += 1 }
	for value := n + 2; value <= 2 * n; value += 1 { values[cursor] = i64(value); cursor += 1 }
	indices: [10]i64
	for i := 0; i < length; i += 1 { indices[i] = i64(i) }
	for {
		total := value_at(values, indices, 0) + value_at(values, indices, 1) + value_at(values, indices, 2)
		magic := true
		minimum_outer := value_at(values, indices, 0)
		for line := 1; line < n; line += 1 {
			outer := 2 * line + 1
			if line == n - 1 { outer = 2 * n - 1 }
			inner_left := 2 * line
			inner_right := 2 * line + 2
			if line == n - 1 { inner_right = 1 }
			if value_at(values, indices, outer) + value_at(values, indices, inner_left) + value_at(values, indices, inner_right) != total { magic = false }
			if value_at(values, indices, outer) < minimum_outer { minimum_outer = value_at(values, indices, outer) }
		}
		if magic && value_at(values, indices, 0) == minimum_outer {
			result := i64(0)
			for line := 0; line < n; line += 1 {
				outer := 2 * line + 1
				inner_left := 2 * line
				inner_right := 2 * line + 2
				if line == 0 { outer = 0; inner_left = 1; inner_right = 2 }
				if line == n - 1 { outer = 2 * n - 1; inner_right = 1 }
				triple := [3]i64{value_at(values, indices, outer), value_at(values, indices, inner_left), value_at(values, indices, inner_right)}
				for part in 0..<3 {
					value := triple[part]
					if value >= 10 { result = result * 100 + value } else { result = result * 10 + value }
				}
			}
			return result
		}
		if !next_permutation(&indices, length) { break }
	}
	return -1
}
