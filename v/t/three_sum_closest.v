module three_sum_closest

const max_items = 512
const invalid_result = i64(-9000000000000000000)

fn absolute_difference(left i64, right i64) i64 {
	difference := left - right
	if difference < 0 { return -difference }
	return difference
}

@[export: 'three_sum_closest']
pub fn three_sum_closest(input &i64, length usize) i64 {
	if length < 2 || length > max_items + 2 { return -9000000000000000000 }
	target := unsafe { input[0] }
	count_value := unsafe { input[1] }
	if target < -2147483648 || target > 2147483647 || count_value < 3 || count_value > max_items { return -9000000000000000000 }
	count := int(count_value)
	if int(length) != count + 2 { return -9000000000000000000 }
	mut values := [max_items]i64{init: 0}
	for index in 0 .. count {
		value := unsafe { input[index + 2] }
		if value < -2147483648 || value > 2147483647 { return -9000000000000000000 }
		values[index] = value
	}
	mut start := count / 2
	for start > 0 {
		start--
		mut root := start
		for root < count / 2 {
			mut child := root * 2 + 1
			if child + 1 < count && values[child] < values[child + 1] { child++ }
			if values[root] >= values[child] { break }
			temporary := values[root]
			values[root] = values[child]
			values[child] = temporary
			root = child
		}
	}
	mut ending := count
	for ending > 1 {
		ending--
		temporary := values[0]
		values[0] = values[ending]
		values[ending] = temporary
		mut root := 0
		for root < ending / 2 {
			mut child := root * 2 + 1
			if child + 1 < ending && values[child] < values[child + 1] { child++ }
			if values[root] >= values[child] { break }
			inner_temporary := values[root]
			values[root] = values[child]
			values[child] = inner_temporary
			root = child
		}
	}
	mut best := values[0] + values[1] + values[2]
	mut best_difference := absolute_difference(target, best)
	for first in 0 .. count - 2 {
		mut left := first + 1
		mut right := count - 1
		for left < right {
			sum := values[first] + values[left] + values[right]
			difference := absolute_difference(target, sum)
			if difference < best_difference || (difference == best_difference && sum < best) {
				best = sum
				best_difference = difference
			}
			if sum < target { left++ } else if sum > target { right-- } else { return sum }
		}
	}
	return best
}
