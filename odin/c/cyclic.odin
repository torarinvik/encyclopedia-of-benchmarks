package cyclic
import "core:c"

rotate_list :: proc "contextless" (next, previous: ^[64]i64, head: ^i64, size, places: i64) {
	if size == 0 do return
	steps := places % size
	if steps < 0 do steps += size
	if steps > size/2 {
		steps = size-steps
		for step := i64(0); step < steps; step += 1 { head^ = previous[head^] }
	} else {
		for step := i64(0); step < steps; step += 1 { head^ = next[head^] }
	}
}

delete_head :: proc "contextless" (values, next, previous: ^[64]i64, head, size: ^i64) -> bool {
	if size^ == 0 do return false
	current := head^
	if size^ == 1 do head^ = -1
	else {
		successor, predecessor := next[current], previous[current]
		next[predecessor] = successor
		previous[successor] = predecessor
		head^ = successor
	}
	values[current] = 0
	size^ -= 1
	return true
}

add_record :: proc "contextless" (records: ^[5000]i64, field_count: ^int, value: i64) {
	records[field_count^] = value
	field_count^ += 1
}

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> u64(byte*8)) & 255) }
}

@(export)
cyclic :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 0 || input[0] > 64 do return -1
	operation_count := int(input[0])
	if length != c.size_t(1+2*operation_count) do return -1
	values: [64]i64
	next: [64]i64
	previous: [64]i64
	head: i64 = -1
	size: i64 = 0
	allocated := 0
	records: [5000]i64
	record_fields := 0
	query_count := 0
	for index := 0; index < operation_count; index += 1 {
		operation, argument := input[1+2*index], input[2+2*index]
		if operation < 0 || operation > 5 do return -1
		if operation == 0 {
			if argument < -2147483648 || argument > 2147483647 || allocated >= 64 do return -1
			node := allocated; allocated += 1; values[node] = argument
			if size == 0 { head = i64(node); next[node] = head; previous[node] = head }
			else { tail := previous[head]; previous[node] = tail; next[node] = head; next[tail] = i64(node); previous[head] = i64(node) }
			size += 1
		} else if operation == 1 {
			if argument < -1000000 || argument > 1000000 do return -1
			rotate_list(&next,&previous,&head,size,argument)
		} else if operation == 2 {
			if argument != 0 do return -1
			deleted := i64(0); if delete_head(&values,&next,&previous,&head,&size) do deleted=1
			add_record(&records,&record_fields,i64(index));add_record(&records,&record_fields,operation);add_record(&records,&record_fields,1);add_record(&records,&record_fields,deleted);query_count+=1
		} else if operation == 3 {
			if argument != 0 do return -1
			add_record(&records,&record_fields,i64(index));add_record(&records,&record_fields,operation);add_record(&records,&record_fields,size)
			cursor:=head
			for item:=i64(0);item<size;item+=1 { add_record(&records,&record_fields,values[cursor]);cursor=next[cursor] }
			query_count+=1
		} else if operation == 4 {
			if argument < -1000000 || argument > 1000000 || size == 0 do return -1
			for size > 1 { rotate_list(&next,&previous,&head,size,argument);_ = delete_head(&values,&next,&previous,&head,&size);rotate_list(&next,&previous,&head,size,-1) }
			winner:=values[head]
			for delete_head(&values,&next,&previous,&head,&size) {}
			add_record(&records,&record_fields,i64(index));add_record(&records,&record_fields,operation);add_record(&records,&record_fields,1);add_record(&records,&record_fields,winner);query_count+=1
		} else {
			if argument != 0 do return -1
			for delete_head(&values,&next,&previous,&head,&size) {}
		}
	}
	required:=(1+record_fields+1+int(size))*8
	if output==nil || capacity<c.size_t(required) do return -2
	field:=0
	put_i64(output,field*8,i64(query_count));field+=1
	for i:=0;i<record_fields;i+=1 { put_i64(output,field*8,records[i]);field+=1 }
	put_i64(output,field*8,size);field+=1
	cursor:=head
	for item:=i64(0);item<size;item+=1 { put_i64(output,field*8,values[cursor]);field+=1;cursor=next[cursor] }
	return i64(required)
}
