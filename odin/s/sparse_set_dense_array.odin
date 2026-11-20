package sparse_set_dense_array

import "core:c"

MAX_UNIVERSE :: 32
MAX_OPERATIONS :: 30
MAX_LENGTH :: 63

@(export)
sparse_set_dense_array :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_LENGTH) do return -1
	if input[0] < 1 || input[0] > MAX_UNIVERSE || input[1] < 0 || input[1] > MAX_OPERATIONS do return -1
	universe := int(input[0])
	count := int(input[1])
	if length != c.size_t(2+2*count) do return -1
	for i := 0; i < count; i += 1 {
		opcode, key := input[2+2*i], input[3+2*i]
		if opcode < 0 || opcode > 3 || key < 0 || key >= i64(universe) do return -1
		if opcode == 3 && key != 0 do return -1
	}

	var dense: [MAX_UNIVERSE]int
	var sparse: [MAX_UNIVERSE]int
	for key := 0; key < universe; key += 1 { sparse[key] = universe }
	size := 0
	answers := i64(0)
	for i := 0; i < count; i += 1 {
		opcode, key := int(input[2+2*i]), int(input[3+2*i])
		index := sparse[key]
		present := index < size && dense[index] == key
		status := i64(0)
		if opcode == 0 {
			if !present {
				dense[size] = key
				sparse[key] = size
				size += 1
				status = 1
			}
		} else if opcode == 1 {
			if present {
				last := dense[size-1]
				dense[index] = last
				sparse[last] = index
				size -= 1
				status = 1
			}
		} else if opcode == 2 {
			if present { status = 1 }
		} else {
			if size > 0 { status = 1 }
			size = 0
		}
		answers = (answers << 1) | status
	}
	final_mask := i64(0)
	for i := 0; i < size; i += 1 { final_mask |= i64(1) << dense[i] }
	return (final_mask << count) | answers
}
