package cursor_linked_list
import "core:c"

find_value :: proc "contextless" (elements: ^[100]i64, occupied: ^[100]bool, links: ^[100]i64,
	head: i64, value: i64, previous, found: ^i64) -> bool {
	previous^ = -1
	found^ = head
	for found^ != -1 && (!occupied[found^] || elements[found^] != value) {
		previous^ = found^
		found^ = links[found^]
	}
	return found^ != -1
}

free_node :: proc "contextless" (elements: ^[100]i64, occupied: ^[100]bool, links: ^[100]i64, index: i64) {
	old_free_head := links[0]
	occupied[index] = false
	elements[index] = 0
	links[index] = old_free_head
	links[0] = index
}

remove_value :: proc "contextless" (elements: ^[100]i64, occupied: ^[100]bool, links: ^[100]i64,
	head, count: ^i64, value: i64) -> bool {
	if head^ == -1 do return false
	previous, current: i64
	if !find_value(elements, occupied, links, head^, value, &previous, &current) do return false
	successor := links[current]
	if previous == -1 { free_node(elements, occupied, links, current); head^ = successor }
	else { links[previous] = successor; free_node(elements, occupied, links, current) }
	count^ -= 1
	return true
}

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> u64(byte*8)) & 255) }
}

@(export)
cursor_linked_list :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 0 || input[0] > 64 do return -1
	operation_count := int(input[0])
	if length != c.size_t(1+2*operation_count) do return -1
	elements: [100]i64
	links: [100]i64
	occupied: [100]bool
	for i := 0; i < 100; i += 1 { links[i] = i64(i+1) }
	links[99] = 0
	head: i64 = -1
	count: i64 = 0
	query_found: [64]i64
	query_values: [64]i64
	query_count := 0
	for index := 0; index < operation_count; index += 1 {
		operation, argument := input[1+2*index], input[2+2*index]
		if operation < 0 || operation > 4 || argument < -2147483648 || argument > 2147483647 do return -1
		if operation == 0 {
			available := links[0]
			if available == 0 do return -1
			links[0] = links[available]; links[available] = -1; elements[available] = argument; occupied[available] = true
			if head == -1 do head = available
			else { tail := head; for links[tail] != -1 { tail = links[tail] }; links[tail] = available }
			links[available] = -1; count += 1
		} else if operation == 1 {
			if !remove_value(&elements, &occupied, &links, &head, &count, argument) do return -1
		} else if operation == 2 {
			if argument < 0 || argument >= count do return -1
			cursor := head
			for i := i64(0); i < argument; i += 1 { cursor = links[cursor] }
			value := elements[cursor]
			if !remove_value(&elements, &occupied, &links, &head, &count, value) do return -1
		} else if operation == 3 {
			if argument >= 0 && argument < count {
				cursor := head
				for i := i64(0); i < argument; i += 1 { cursor = links[cursor] }
				query_found[query_count] = 1; query_values[query_count] = elements[cursor]
			}
			query_count += 1
		} else {
			previous, found: i64
			if find_value(&elements, &occupied, &links, head, argument, &previous, &found) {
				logical_index, cursor: i64 = 0, head
				for cursor != found { cursor = links[cursor]; logical_index += 1 }
				query_found[query_count] = 1; query_values[query_count] = logical_index
			}
			query_count += 1
		}
	}
	required := (1+2*query_count+2+3*100)*8
	if output == nil || capacity < c.size_t(required) do return -2
	field := 0
	put_i64(output, field*8, i64(query_count)); field += 1
	for i := 0; i < query_count; i += 1 { put_i64(output,field*8,query_found[i]);field+=1;put_i64(output,field*8,query_values[i]);field+=1 }
	put_i64(output,field*8,head);field+=1;put_i64(output,field*8,count);field+=1
	for i := 0; i < 100; i += 1 { present := i64(0); if occupied[i] do present=1; put_i64(output,field*8,present);field+=1;put_i64(output,field*8,elements[i]);field+=1;put_i64(output,field*8,links[i]);field+=1 }
	return i64(required)
}
