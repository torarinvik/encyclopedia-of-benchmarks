module link_list_sort

@[export: 'link_list_sort']
pub fn link_list_sort(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 130 { return -1 }
	selector := unsafe { input[0] }
	count_value := unsafe { input[1] }
	if selector < 1 || selector > 3 || count_value < 0 || count_value > 128 { return -1 }
	count := int(count_value)
	if length != usize(2 + count) { return -1 }
	mut items := [128]i32{}
	mut scratch := [128]i32{}
	for i in 0 .. count {
		value := unsafe { input[2 + i] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		items[i] = i32(value)
	}
	if selector == 1 {
		mut width := 1
		for width < count {
			mut start := 0
			for start < count {
				middle := if start + width < count { start + width } else { count }
				finish := if middle + width < count { middle + width } else { count }
				mut left := start
				mut right := middle
				mut out_index := start
				for left < middle && right < finish {
					if items[left] <= items[right] { scratch[out_index] = items[left]; left++ }
					else { scratch[out_index] = items[right]; right++ }
					out_index++
				}
				for left < middle { scratch[out_index] = items[left]; left++; out_index++ }
				for right < finish { scratch[out_index] = items[right]; right++; out_index++ }
				start = finish
			}
			for i in 0 .. count { items[i] = scratch[i] }
			width *= 2
		}
	} else if selector == 2 {
		for i in 1 .. count {
			value := items[i]
			mut j := i
			for j > 0 && items[j - 1] > value { items[j] = items[j - 1]; j-- }
			items[j] = value
		}
	} else {
		mut start := count / 2
		for start > 0 {
			start--
			mut root := start
			for root < count / 2 {
				mut child := 2 * root + 1
				if child + 1 < count && items[child + 1] > items[child] { child++ }
				if items[root] >= items[child] { break }
				value := items[root]; items[root] = items[child]; items[child] = value
				root = child
			}
		}
		mut end_index := count
		for end_index > 1 {
			end_index--
			mut value := items[0]; items[0] = items[end_index]; items[end_index] = value
			mut root := 0
			for root < end_index / 2 {
				mut child := 2 * root + 1
				if child + 1 < end_index && items[child + 1] > items[child] { child++ }
				if items[root] >= items[child] { break }
				value = items[root]; items[root] = items[child]; items[child] = value
				root = child
			}
		}
	}
	required := 4 * count
	if output == nil || output_capacity < usize(required) { return -2 }
	for i in 0 .. count {
		bits := u32(items[i])
		for byte in 0 .. 4 { unsafe { output[4 * i + byte] = u8((bits >> (8 * byte)) & 255) } }
	}
	return i64(required)
}
