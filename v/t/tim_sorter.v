module tim_sorter

const max_items = 512
const min_merge = 32
const max_parseable_input_length = 1026
const hash_multiplier = i64(1000003)
const hash_modulus = i64(1000000007)

struct Item {
	key i64
	id  i64
}

fn binary_sort(mut items [max_items]Item, start int, end int, first_arg int) {
	mut first := first_arg
	if first >= end || first <= start { first = start + 1 }
	for first < end {
		target := items[first]
		mut left, mut right := start, first
		for left < right {
			middle := (left + right) >> 1
			if target.key < items[middle].key { right = middle } else { left = middle + 1 }
		}
		mut cursor := first
		for cursor > left { items[cursor] = items[cursor - 1]; cursor-- }
		items[left] = target
		first++
	}
}

fn count_run_and_make_ascending(mut items [max_items]Item, start int, length int) int {
	mut end := start + 1
	if end == length { return 1 }
	if items[end].key < items[start].key {
		end++
		for end < length && items[end].key < items[end - 1].key { end++ }
		mut left, mut right := start, end - 1
		for left < right { items[left], items[right] = items[right], items[left]; left++; right-- }
	} else {
		end++
		for end < length && items[end].key >= items[end - 1].key { end++ }
	}
	return end - start
}

fn min_run_length(total_arg int) int {
	mut total, mut remainder := total_arg, 0
	for total >= min_merge { remainder |= total & 1; total >>= 1 }
	return total + remainder
}

fn merge_at(mut items [max_items]Item, mut temp [max_items]Item,
	mut run_base [85]int, mut run_length [85]int, mut stack_size int, index int) {
	base_a, len_a := run_base[index], run_length[index]
	base_b, len_b := run_base[index + 1], run_length[index + 1]
	run_length[index] = len_a + len_b
	if index == stack_size - 3 {
		run_base[index + 1], run_length[index + 1] = run_base[index + 2], run_length[index + 2]
	}
	stack_size--
	for i in 0 .. len_a { temp[i] = items[base_a + i] }
	mut left, mut right, mut dest := 0, base_b, base_a
	end_b := base_b + len_b
	for left < len_a && right < end_b {
		if items[right].key < temp[left].key { items[dest] = items[right]; right++ }
		else { items[dest] = temp[left]; left++ }
		dest++
	}
	for left < len_a { items[dest] = temp[left]; left++; dest++ }
}

fn merge_collapse(mut items [max_items]Item, mut temp [max_items]Item,
	mut run_base [85]int, mut run_length [85]int, mut stack_size int) {
	for stack_size > 1 {
		mut n := stack_size - 2
		if n > 0 && run_length[n - 1] <= run_length[n] + run_length[n + 1] {
			if run_length[n - 1] < run_length[n + 1] { n-- }
			merge_at(mut items, mut temp, mut run_base, mut run_length, mut stack_size, n)
		} else if run_length[n] <= run_length[n + 1] {
			merge_at(mut items, mut temp, mut run_base, mut run_length, mut stack_size, n)
		} else { break }
	}
}

fn tim_sort(mut items [max_items]Item, length int) {
	if length < min_merge { binary_sort(mut items, 0, length, 0); return }
	min_run := min_run_length(length)
	mut run_base := [85]int{}
	mut run_length := [85]int{}
	mut temp := [max_items]Item{}
	mut stack_size, mut start, mut remaining := 0, 0, length
	for remaining > 0 {
		mut current_run := count_run_and_make_ascending(mut items, start, length)
		if current_run < min_run {
			force := if min_run < remaining { min_run } else { remaining }
			binary_sort(mut items, start, start + force, start + current_run)
			current_run = force
		}
		run_base[stack_size], run_length[stack_size] = start, current_run
		stack_size++
		merge_collapse(mut items, mut temp, mut run_base, mut run_length, mut stack_size)
		start += current_run
		remaining -= current_run
	}
	for stack_size > 1 {
		mut n := stack_size - 2
		if n > 0 && run_length[n - 1] < run_length[n + 1] { n-- }
		merge_at(mut items, mut temp, mut run_base, mut run_length, mut stack_size, n)
	}
}

@[export: 'tim_sorter_benchmark']
pub fn tim_sorter_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_items { return -1 }
		count := int(input[0])
		if length != usize(1 + 2 * count) { return -1 }
		mut items := [max_items]Item{}
		mut seen := [max_items]bool{}
		for index in 0 .. count {
			key, id := input[1 + 2 * index], input[2 + 2 * index]
			if key < -1000 || key > 1000 || id < 0 || id >= i64(count) { return -1 }
			if seen[int(id)] { return -1 }
			seen[int(id)] = true
			items[index] = Item{key: key, id: id}
		}
		tim_sort(mut items, count)
		mut checksum := i64(0)
		for index in 0 .. count {
			token := (items[index].key + 1000) * 513 + items[index].id + 1
			checksum = (checksum * hash_multiplier + token) % hash_modulus
		}
		return checksum
	}
}
