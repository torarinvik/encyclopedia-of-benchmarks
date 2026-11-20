package lcfs_hashing

import "core:c"

MAX_CAPACITY :: 32
MAX_INPUT_LENGTH :: 35
MAX_KEY :: i64(1_000_000)

@(export)
lcfs_hashing :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	capacity_value := input[0]
	count_value := input[1]
	if capacity_value < 1 || capacity_value > MAX_CAPACITY || count_value < 0 || count_value > capacity_value do return -1
	if length != c.size_t(count_value + 2) do return -1
	capacity := int(capacity_value)
	count := int(count_value)
	for i in 0..<count {
		key := input[i + 2]
		if key < 0 || key > MAX_KEY do return -1
		for j in 0..<i { if input[j + 2] == key do return -1 }
	}

	table: [MAX_CAPACITY]i64
	for i in 0..<capacity { table[i] = -1 }
	displacements: i64 = 0
	for i in 0..<count {
		incoming := input[i + 2]
		slot := int(incoming % capacity_value)
		probes := 0
		for table[slot] != -1 {
			if probes >= capacity do return -1
			resident := table[slot]
			table[slot] = incoming
			incoming = resident
			slot = (slot + 1) % capacity
			probes += 1
			displacements += 1
		}
		table[slot] = incoming
	}
	return displacements
}
