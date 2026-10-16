module problem68

fn value_at(values [10]int, indices [10]int, position int) int {
	return values[indices[position]]
}

fn next_permutation(mut indices [10]int, length int) bool {
	mut pivot := length - 2
	for pivot >= 0 && indices[pivot] >= indices[pivot + 1] { pivot-- }
	if pivot < 0 { return false }
	mut successor := length - 1
	for indices[successor] <= indices[pivot] { successor-- }
	temp := indices[pivot]
	indices[pivot] = indices[successor]
	indices[successor] = temp
	mut left := pivot + 1
	mut right := length - 1
	for left < right {
		temp = indices[left]; indices[left] = indices[right]; indices[right] = temp
		left++; right--
	}
	return true
}

@[export: 'problem68']
pub fn problem68(gon_side i64) i64 {
	if gon_side < 3 || gon_side > 5 { return -1 }
	n := int(gon_side)
	length := 2 * n
	mut values := [10]int{}
	mut cursor := 0
	for value := n + 1; value >= 1; value-- { values[cursor] = value; cursor++ }
	for value := n + 2; value <= 2 * n; value++ { values[cursor] = value; cursor++ }
	mut indices := [10]int{}
	for i in 0 .. length { indices[i] = i }
	for {
		total := value_at(values, indices, 0) + value_at(values, indices, 1) + value_at(values, indices, 2)
		mut magic := true
		mut minimum_outer := value_at(values, indices, 0)
		for line in 1 .. n {
			outer := if line == n - 1 { 2 * n - 1 } else { 2 * line + 1 }
			inner_left := 2 * line
			inner_right := if line == n - 1 { 1 } else { 2 * line + 2 }
			if value_at(values, indices, outer) + value_at(values, indices, inner_left) + value_at(values, indices, inner_right) != total { magic = false }
			if value_at(values, indices, outer) < minimum_outer { minimum_outer = value_at(values, indices, outer) }
		}
		if magic && value_at(values, indices, 0) == minimum_outer {
			mut result := i64(0)
			for line in 0 .. n {
				outer := if line == 0 { 0 } else if line == n - 1 { 2 * n - 1 } else { 2 * line + 1 }
				inner_left := if line == 0 { 1 } else { 2 * line }
				inner_right := if line == n - 1 { 1 } else if line == 0 { 2 } else { 2 * line + 2 }
				for value in [value_at(values, indices, outer), value_at(values, indices, inner_left), value_at(values, indices, inner_right)] {
					if value >= 10 { result = result * 100 + value } else { result = result * 10 + value }
				}
			}
			return result
		}
		if !next_permutation(mut indices, length) { break }
	}
	return -1
}
