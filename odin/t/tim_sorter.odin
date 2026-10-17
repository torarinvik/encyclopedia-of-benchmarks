package tim_sorter

import "core:c"

MAX_ITEMS :: 512
MIN_MERGE :: 32
MAX_TREE_STACK :: 85
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(1026)
HASH_MULTIPLIER :: i64(1000003)
HASH_MODULUS :: i64(1000000007)

Item :: struct { key: i64, id: i64 }

binary_sort :: proc "contextless" (items: [^]Item, start, end: int, first_arg: int) {
	first := first_arg
	if first >= end || first <= start { first = start+1 }
	for first < end {
		target := items[first]
		left, right := start, first
		for left < right {
			middle := (left+right)>>1
			if target.key < items[middle].key { right = middle } else { left = middle+1 }
		}
		cursor := first
		for cursor > left { items[cursor] = items[cursor-1]; cursor -= 1 }
		items[left] = target
		first += 1
	}
}

count_run_and_make_ascending :: proc "contextless" (items: [^]Item, start, length: int) -> int {
	end := start+1
	if end == length do return 1
	if items[end].key < items[start].key {
		end += 1
		for end < length && items[end].key < items[end-1].key { end += 1 }
		left, right := start, end-1
		for left < right { items[left], items[right] = items[right], items[left]; left += 1; right -= 1 }
	} else {
		end += 1
		for end < length && items[end].key >= items[end-1].key { end += 1 }
	}
	return end-start
}

min_run_length :: proc "contextless" (total_arg: int) -> int {
	total, remainder := total_arg, 0
	for total >= MIN_MERGE { remainder |= total&1; total >>= 1 }
	return total+remainder
}

merge_at :: proc "contextless" (items, temp: [^]Item, run_base, run_length: [^]int, stack_size: ^int, index: int) {
	base_a, len_a := run_base[index], run_length[index]
	base_b, len_b := run_base[index+1], run_length[index+1]
	run_length[index] = len_a+len_b
	if index == stack_size^ - 3 { run_base[index+1], run_length[index+1] = run_base[index+2], run_length[index+2] }
	stack_size^ -= 1
	for i in 0..<len_a { temp[i] = items[base_a+i] }
	left, right, dest := 0, base_b, base_a
	end_b := base_b+len_b
	for left < len_a && right < end_b {
		if items[right].key < temp[left].key { items[dest] = items[right]; right += 1 }
		else { items[dest] = temp[left]; left += 1 }
		dest += 1
	}
	for left < len_a { items[dest] = temp[left]; left += 1; dest += 1 }
}

merge_collapse :: proc "contextless" (items, temp: [^]Item, run_base, run_length: [^]int, stack_size: ^int) {
	for stack_size^ > 1 {
		n := stack_size^ - 2
		if n > 0 && run_length[n-1] <= run_length[n]+run_length[n+1] {
			if run_length[n-1] < run_length[n+1] { n -= 1 }
			merge_at(items, temp, run_base, run_length, stack_size, n)
		} else if run_length[n] <= run_length[n+1] {
			merge_at(items, temp, run_base, run_length, stack_size, n)
		} else { break }
	}
}

tim_sort :: proc "contextless" (items: [^]Item, length: int) {
	if length < MIN_MERGE { binary_sort(items, 0, length, 0); return }
	min_run := min_run_length(length)
	var run_base: [MAX_TREE_STACK]int
	var run_length: [MAX_TREE_STACK]int
	var temp: [MAX_ITEMS]Item
	stack_size, start, remaining := 0, 0, length
	for remaining > 0 {
		current_run := count_run_and_make_ascending(items, start, length)
		if current_run < min_run {
			force := min(min_run, remaining)
			binary_sort(items, start, start+force, start+current_run)
			current_run = force
		}
		run_base[stack_size], run_length[stack_size] = start, current_run
		stack_size += 1
		merge_collapse(items, &temp[0], &run_base[0], &run_length[0], &stack_size)
		start += current_run
		remaining -= current_run
	}
	for stack_size > 1 {
		n := stack_size-2
		if n > 0 && run_length[n-1] < run_length[n+1] { n -= 1 }
		merge_at(items, &temp[0], &run_base[0], &run_length[0], &stack_size, n)
	}
}

tim_sorter_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_ITEMS do return -1
	count := int(input[0])
	if length != c.size_t(1+2*count) do return -1
	var items: [MAX_ITEMS]Item
	var seen: [MAX_ITEMS]bool
	for index in 0..<count {
		key, id := input[1+2*index], input[2+2*index]
		if key < -1000 || key > 1000 || id < 0 || id >= i64(count) do return -1
		if seen[int(id)] do return -1
		seen[int(id)] = true
		items[index] = Item{key, id}
	}
	tim_sort(&items[0], count)
	checksum := i64(0)
	for index in 0..<count {
		token := (items[index].key+1000)*513+items[index].id+1
		checksum = (checksum*HASH_MULTIPLIER+token)%HASH_MODULUS
	}
	return checksum
}
