module merge_sorted_singly_linked_list

const max_nodes = 128
const max_input_length = 130
const max_output_bytes = 1536

struct ListNode {
	value i32
	next i32
	origin i32
	position i32
}

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'merge_sorted_singly_linked_list']
pub fn merge_sorted_singly_linked_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		if input[0] < 0 || input[0] > max_nodes { return -1 }
		len_a := int(input[0])
		if len_a > int(length) - 2 { return -1 }
		len_b_pos := 1 + len_a
		raw_len_b := input[len_b_pos]
		if raw_len_b < 0 || raw_len_b > i64(max_nodes - len_a) { return -1 }
		len_b := int(raw_len_b)
		total := len_a + len_b
		if int(length) != 2 + total { return -1 }

		mut nodes := [max_nodes]ListNode{}
		for i in 0 .. len_a {
			raw := input[1 + i]
			if raw < -2147483648 || raw > 2147483647 || (i > 0 && input[i] > raw) { return -1 }
			next := if i + 1 < len_a { i32(i + 1) } else { i32(-1) }
			nodes[i] = ListNode{value: i32(raw), next: next, origin: 0, position: i32(i)}
		}
		b_start := len_b_pos + 1
		for i in 0 .. len_b {
			raw := input[b_start + i]
			if raw < -2147483648 || raw > 2147483647 || (i > 0 && input[b_start + i - 1] > raw) { return -1 }
			node := len_a + i
			next := if i + 1 < len_b { i32(node + 1) } else { i32(-1) }
			nodes[node] = ListNode{value: i32(raw), next: next, origin: 1, position: i32(i)}
		}

		mut head_a := if len_a == 0 { i32(-1) } else { i32(0) }
		mut head_b := if len_b == 0 { i32(-1) } else { i32(len_a) }
		mut merged_head := i32(-1)
		mut tail := i32(-1)
		for head_a >= 0 && head_b >= 0 {
			mut node := i32(-1)
			if nodes[int(head_a)].value <= nodes[int(head_b)].value {
				node = head_a
				head_a = nodes[int(node)].next
			} else {
				node = head_b
				head_b = nodes[int(node)].next
			}
			if tail < 0 { merged_head = node }
			else { nodes[int(tail)].next = node }
			tail = node
		}
		remainder := if head_a >= 0 { head_a } else { head_b }
		if tail < 0 { merged_head = remainder }
		else { nodes[int(tail)].next = remainder }

		output_bytes := 12 * total
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut buffer := [max_output_bytes]u8{}
		mut written := 0
		mut node := merged_head
		for node >= 0 {
			item := nodes[int(node)]
			put_i32_le(mut buffer[0], written, item.value)
			put_i32_le(mut buffer[0], written + 4, item.origin)
			put_i32_le(mut buffer[0], written + 8, item.position)
			written += 12
			node = item.next
		}
		for i in 0 .. output_bytes { output[i] = buffer[i] }
		return i64(output_bytes)
	}
}
