package merge_sort_linked_list

import "core:c"

merge_nodes :: proc(values: ^[128]i32, links: ^[128]i32, left, right: i32) -> i32 {
	if left < 0 do return right
	if right < 0 do return left
	left_index := int(left)
	right_index := int(right)
	if values[left_index] <= values[right_index] {
		links[left_index] = merge_nodes(values, links, links[left_index], right)
		return left
	}
	links[right_index] = merge_nodes(values, links, left, links[right_index])
	return right
}

merge_sort_nodes :: proc(values: ^[128]i32, links: ^[128]i32, head: i32) -> i32 {
	if head < 0 || links[int(head)] < 0 do return head
	slow := head
	fast := links[int(head)]
	for fast >= 0 && links[int(fast)] >= 0 {
		slow = links[int(slow)]
		fast = links[int(links[int(fast)])]
	}
	right_head := links[int(slow)]
	links[int(slow)] = -1
	left := merge_sort_nodes(values, links, head)
	right := merge_sort_nodes(values, links, right_head)
	return merge_nodes(values, links, left, right)
}

@(export)
merge_sort_linked_list :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 129 do return -1
	count_value := input[0]
	if count_value < 0 || count_value > 128 do return -1
	count := int(count_value)
	if length != c.size_t(1 + count) do return -1
	values: [128]i32 = {}
	links: [128]i32 = {}
	for i := 0; i < count; i += 1 {
		value := input[1 + i]
		if value < -2147483648 || value > 2147483647 do return -1
		values[i] = i32(value)
		for j := 0; j < i; j += 1 { if values[j] == values[i] do return -1 }
		links[i] = -1
		if i + 1 < count do links[i] = i32(i + 1)
	}
	head := i32(-1)
	if count > 0 do head = merge_sort_nodes(&values, &links, 0)
	required := 4 * count
	if output == nil || output_capacity < c.size_t(required) do return -2
	node := head
	for i := 0; i < count; i += 1 {
		bits := u32(values[int(node)])
		for byte := 0; byte < 4; byte += 1 { output[4 * i + byte] = u8((bits >> (8 * byte)) & 255) }
		node = links[int(node)]
	}
	return i64(required)
}
