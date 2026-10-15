package count_distinct_elements_in_window

import "core:c"

MAX_N :: 256
HASH_CAPACITY :: 512

hash_slot :: proc "contextless" (value: i32) -> int {
	bits := u32(value)
	mixed := u64(bits) * 2_654_435_761
	return int(u32(mixed) >> 23)
}

find_slot :: proc "contextless" (keys: [^]i32, occupied: [^]bool, value: i32) -> int {
	slot := hash_slot(value)
	for probes := 0; probes < HASH_CAPACITY; probes += 1 {
		if !occupied[slot] || keys[slot] == value do return slot
		slot = (slot + 1) % HASH_CAPACITY
	}
	return 0
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte: usize = 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
count_distinct_elements_in_window :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if input[1] < 1 || input[1] > i64(n) || length != c.size_t(n + 2) do return -1
	k := int(input[1])
	out_n := n - k + 1
	for i := 0; i < n; i += 1 { if input[i + 2] < -2147483648 || input[i + 2] > 2147483647 do return -1 }
	if output == nil || capacity < c.size_t(out_n * 8) do return -2

	keys: [HASH_CAPACITY]i32
	counts: [HASH_CAPACITY]i32 = {}
	occupied: [HASH_CAPACITY]bool = {}
	distinct: i64 = 0
	for i := 0; i < k; i += 1 {
		value := i32(input[i + 2])
		slot := find_slot(&keys[0], &occupied[0], value)
		if !occupied[slot] { keys[slot] = value; occupied[slot] = true; counts[slot] = 0 }
		if counts[slot] == 0 do distinct += 1
		counts[slot] += 1
	}
	put_i64_le(output, 0, distinct)
	for i := k; i < n; i += 1 {
		incoming := i32(input[i + 2])
		slot := find_slot(&keys[0], &occupied[0], incoming)
		if !occupied[slot] { keys[slot] = incoming; occupied[slot] = true; counts[slot] = 0 }
		if counts[slot] == 0 do distinct += 1
		counts[slot] += 1
		outgoing := i32(input[i - k + 2])
		slot = find_slot(&keys[0], &occupied[0], outgoing)
		counts[slot] -= 1
		if counts[slot] == 0 do distinct -= 1
		put_i64_le(output, (i - k + 1) * 8, distinct)
	}
	return i64(out_n * 8)
}
