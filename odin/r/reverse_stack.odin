package reverse_stack

import "core:c"

MAX_ELEMENTS :: 16

insert_at_bottom :: proc "contextless" (items: [^]i64, size: int, value: i64) {
	if size == 0 { items[0] = value; return }
	top := items[size-1]
	insert_at_bottom(items, size-1, value)
	items[size] = top
}

reverse_recursive :: proc "contextless" (items: [^]i64, size: int) {
	if size == 0 do return
	top := items[size-1]
	reverse_recursive(items, size-1)
	insert_at_bottom(items, size-1, top)
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
reverse_stack :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	raw_count := input[0]
	if raw_count < 0 || raw_count > MAX_ELEMENTS || length != c.size_t(raw_count+1) do return -1
	count := int(raw_count)
	items: [MAX_ELEMENTS]i64
	for i := 0; i < count; i += 1 {
		if input[i+1] < -1_000_000 || input[i+1] > 1_000_000 do return -1
		items[i] = input[i+1]
	}
	bytes := (count+1)*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	reverse_recursive(&items[0], count)
	put_i64_le(output, 0, raw_count)
	for i := 0; i < count; i += 1 { put_i64_le(output, 8*(i+1), items[i]) }
	return i64(bytes)
}
