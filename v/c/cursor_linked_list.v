module cursor_linked_list

fn find_value(elements &i64, occupied &bool, links &i64, head i64, value i64, mut previous &i64, mut found &i64) bool {
	unsafe {
		previous = -1
		found = head
		for found != -1 && (!occupied[int(found)] || elements[int(found)] != value) {
			previous = found
			found = links[int(found)]
		}
		return found != -1
	}
}

fn free_node(mut elements &i64, mut occupied &bool, mut links &i64, index int) {
	unsafe {
		old_free_head := links[0]
		occupied[index] = false
		elements[index] = 0
		links[index] = old_free_head
		links[0] = i64(index)
	}
}

fn remove_value(mut elements &i64, mut occupied &bool, mut links &i64, mut head &i64, mut count &i64, value i64) bool {
	if head == -1 { return false }
	mut previous := i64(-1)
	mut current := head
	if !find_value(elements, occupied, links, head, value, mut previous, mut current) { return false }
	unsafe {
		successor := links[int(current)]
		if previous == -1 {
			free_node(mut elements, mut occupied, mut links, int(current))
			head = successor
		} else {
			links[int(previous)] = successor
			free_node(mut elements, mut occupied, mut links, int(current))
		}
		count--
	}
	return true
}

fn put_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'cursor_linked_list']
pub fn cursor_linked_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 64 { return -1 }
		operation_count := int(input[0])
		if length != usize(1 + 2 * operation_count) { return -1 }
		mut elements := [100]i64{}
		mut links := [100]i64{}
		mut occupied := [100]bool{}
		for i in 0 .. 100 { links[i] = i64(i + 1) }
		links[99] = 0
		mut head := i64(-1)
		mut count := i64(0)
		mut query_found := [64]i64{}
		mut query_values := [64]i64{}
		mut query_count := 0
		for index in 0 .. operation_count {
			operation, argument := input[1 + 2 * index], input[2 + 2 * index]
			if operation < 0 || operation > 4 || argument < -2147483648 || argument > 2147483647 { return -1 }
			if operation == 0 {
				available := int(links[0])
				if available == 0 { return -1 }
				links[0] = links[available]
				links[available] = -1
				elements[available] = argument
				occupied[available] = true
				if head == -1 { head = i64(available) }
				else {
					mut tail := int(head)
					for links[tail] != -1 { tail = int(links[tail]) }
					links[tail] = i64(available)
				}
				links[available] = -1
				count++
			} else if operation == 1 {
				if !remove_value(mut elements[0], mut occupied[0], mut links[0], mut head, mut count, argument) { return -1 }
			} else if operation == 2 {
				if argument < 0 || argument >= count { return -1 }
				mut cursor := int(head)
				for i in 0 .. int(argument) { cursor = int(links[cursor]) }
				value := elements[cursor]
				if !remove_value(mut elements[0], mut occupied[0], mut links[0], mut head, mut count, value) { return -1 }
			} else if operation == 3 {
				if argument >= 0 && argument < count {
					mut cursor := int(head)
					for i in 0 .. int(argument) { cursor = int(links[cursor]) }
					query_found[query_count] = 1
					query_values[query_count] = elements[cursor]
				}
				query_count++
			} else {
				mut previous := i64(-1)
				mut found := i64(-1)
				if find_value(elements[0], occupied[0], links[0], head, argument, mut previous, mut found) {
					mut logical_index := i64(0)
					mut cursor := head
					for cursor != found { cursor = links[int(cursor)]; logical_index++ }
					query_found[query_count] = 1
					query_values[query_count] = logical_index
				}
				query_count++
			}
		}
		required := (1 + 2 * query_count + 2 + 3 * 100) * 8
		if output == nil || capacity < usize(required) { return -2 }
		mut field := 0
		put_i64(mut output, field * 8, i64(query_count))
		field++
		for i in 0 .. query_count {
			put_i64(mut output, field * 8, query_found[i]); field++
			put_i64(mut output, field * 8, query_values[i]); field++
		}
		put_i64(mut output, field * 8, head); field++
		put_i64(mut output, field * 8, count); field++
		for i in 0 .. 100 {
			present := if occupied[i] { i64(1) } else { i64(0) }
			put_i64(mut output, field * 8, present); field++
			put_i64(mut output, field * 8, elements[i]); field++
			put_i64(mut output, field * 8, links[i]); field++
		}
		return i64(required)
	}
}
