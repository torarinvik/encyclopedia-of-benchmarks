module bfprt

const max_size = 1024
const invalid = i64(-2147483649)

fn swap_values(mut values []i32, left int, right int) {
	values[left], values[right] = values[right], values[left]
}

fn insertion_sort(mut values []i32, left int, right int) {
	mut index := left + 1
	for index <= right {
		mut cursor := index
		for cursor > left && values[cursor - 1] > values[cursor] {
			swap_values(mut values, cursor - 1, cursor)
			cursor--
		}
		index++
	}
}

fn median_of_medians(mut values []i32, left int, right int) i32 {
	count := right - left + 1
	groups := (count + 4) / 5
	for group in 0 .. groups {
		group_left := left + group * 5
		mut group_right := group_left + 4
		if group_right > right { group_right = right }
		insertion_sort(mut values, group_left, group_right)
		median := group_left + (group_right - group_left + 1) / 2
		swap_values(mut values, left + group, median)
	}
	if groups == 1 { return values[left] }
	return select_bfprt(mut values, left, left + groups - 1, left + groups / 2)
}

fn select_bfprt(mut values []i32, left_value int, right_value int, rank int) i32 {
	mut left := left_value
	mut right := right_value
	for left < right {
		pivot := median_of_medians(mut values, left, right)
		mut less := left
		mut current := left
		mut greater := right + 1
		for current < greater {
			if values[current] < pivot {
				swap_values(mut values, less, current)
				less++
				current++
			} else if values[current] > pivot {
				greater--
				swap_values(mut values, current, greater)
			} else {
				current++
			}
		}
		if rank < less {
			right = less - 1
		} else if rank >= greater {
			left = greater
		} else {
			return values[rank]
		}
	}
	return values[left]
}

@[export: 'bfprt']
pub fn bfprt(input &i64, length usize) i64 {
	unsafe {
		if isnil(input) || length < 2 { return invalid }
		nv := input[0]
		rank_value := input[1]
		if nv < 1 || nv > max_size { return invalid }
		n := int(nv)
		if length != usize(n + 2) || rank_value < 1 || rank_value > nv { return invalid }
		mut values := []i32{len: n}
		for index in 0 .. n {
			value := input[index + 2]
			if value < -2147483648 || value > 2147483647 { return invalid }
			values[index] = i32(value)
		}
		return i64(select_bfprt(mut values, 0, n - 1, int(rank_value - 1)))
	}
}
