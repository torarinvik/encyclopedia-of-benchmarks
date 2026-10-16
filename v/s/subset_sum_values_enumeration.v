module subset_sum_values_enumeration

const max_items = 11
const max_target = i64(256)
const max_item = i64(64)

fn write_i64_le(mut output &u8, mut position &usize, value i64) {
	mut bits := u64(value)
	for _ in 0 .. 8 {
		unsafe { output[position[0]] = u8(bits & 0xff) }
		bits >>= 8
		position[0]++
	}
}

fn enumerate(input &i64, item_count int, index int, target i64, total i64,
		mut chosen []i64, chosen_count int, mut output &u8, mut position &usize, emit bool) usize {
	if total == target {
		if emit {
			write_i64_le(mut output, mut position, i64(chosen_count))
			for i in 0 .. chosen_count { write_i64_le(mut output, mut position, chosen[i]) }
		}
		return usize(chosen_count + 1)
	}
	if index == item_count || total > target { return 0 }
	unsafe { chosen[chosen_count] = input[index + 1] }
	include_slots := enumerate(input, item_count, index + 1, target,
		total + unsafe { input[index + 1] }, mut chosen, chosen_count + 1, mut output, mut position, emit)
	exclude_slots := enumerate(input, item_count, index + 1, target,
		total, mut chosen, chosen_count, mut output, mut position, emit)
	return include_slots + exclude_slots
}

@[export: 'subset_sum_values_enumeration']
pub fn subset_sum_values_enumeration(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length == 0 || length > max_items + 1 || unsafe { input == nil } { return -1 }
	unsafe {
		target := input[0]
		if target < 0 || target > max_target { return -1 }
		items := int(length) - 1
		for index in 0 .. items {
			item := input[index + 1]
			if item < 1 || item > max_item { return -1 }
		}
		mut chosen := []i64{len: max_items}
		mut dummy_position := usize(0)
		slots := enumerate(input, items, 0, target, 0, mut chosen, 0,
			mut output, mut dummy_position, false)
		required := slots * 8
		if required == 0 { return 0 }
		if output == nil || output_capacity < required { return -2 }
		mut position := usize(0)
		enumerate(input, items, 0, target, 0, mut chosen, 0,
			mut output, mut position, true)
		return i64(position)
	}
}
