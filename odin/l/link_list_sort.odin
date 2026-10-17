package link_list_sort

import "core:c"

@(export)
link_list_sort :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 130 do return -1
	selector := input[0]
	count_value := input[1]
	if selector < 1 || selector > 3 || count_value < 0 || count_value > 128 do return -1
	count := int(count_value)
	if length != c.size_t(2 + count) do return -1
	items: [128]i32 = {}
	scratch: [128]i32 = {}
	for i := 0; i < count; i += 1 {
		value := input[2 + i]
		if value < -2147483648 || value > 2147483647 do return -1
		items[i] = i32(value)
	}
	if selector == 1 {
		width := 1
		for width < count {
			start := 0
			for start < count {
				middle := start + width
				if middle > count do middle = count
				finish := middle + width
				if finish > count do finish = count
				left := start
				right := middle
				out_index := start
				for left < middle && right < finish {
					if items[left] <= items[right] { scratch[out_index] = items[left]; left += 1 }
					else { scratch[out_index] = items[right]; right += 1 }
					out_index += 1
				}
				for left < middle { scratch[out_index] = items[left]; left += 1; out_index += 1 }
				for right < finish { scratch[out_index] = items[right]; right += 1; out_index += 1 }
				start = finish
			}
			for i := 0; i < count; i += 1 { items[i] = scratch[i] }
			width *= 2
		}
	} else if selector == 2 {
		for i := 1; i < count; i += 1 {
			value := items[i]
			j := i
			for j > 0 && items[j - 1] > value { items[j] = items[j - 1]; j -= 1 }
			items[j] = value
		}
	} else {
		start := count / 2
		for start > 0 {
			start -= 1
			root := start
			for root < count / 2 {
				child := 2 * root + 1
				if child + 1 < count && items[child + 1] > items[child] do child += 1
				if items[root] >= items[child] do break
				value := items[root]; items[root] = items[child]; items[child] = value
				root = child
			}
		}
		end_index := count
		for end_index > 1 {
			end_index -= 1
			value := items[0]; items[0] = items[end_index]; items[end_index] = value
			root := 0
			for root < end_index / 2 {
				child := 2 * root + 1
				if child + 1 < end_index && items[child + 1] > items[child] do child += 1
				if items[root] >= items[child] do break
				value = items[root]; items[root] = items[child]; items[child] = value
				root = child
			}
		}
	}
	required := 4 * count
	if output == nil || output_capacity < c.size_t(required) do return -2
	for i := 0; i < count; i += 1 {
		bits := u32(items[i])
		for byte := 0; byte < 4; byte += 1 { output[4 * i + byte] = u8((bits >> (8 * byte)) & 255) }
	}
	return i64(required)
}
