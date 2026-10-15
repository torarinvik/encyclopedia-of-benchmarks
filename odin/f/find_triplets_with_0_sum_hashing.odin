package find_triplets_with_0_sum_hashing

import "core:c"

MAX_ITEMS :: 64
MAX_TRIPLETS :: 2048
HASH_CAPACITY :: 128
BYTES_PER_TRIPLET :: 12

hash_slot :: proc "contextless" (value: i64) -> int { return int((value + 100000) * 37 % HASH_CAPACITY) }

seen_contains :: proc "contextless" (keys: [^]i64, occupied: [^]bool, value: i64) -> bool {
	slot := hash_slot(value)
	for probes := 0; probes < HASH_CAPACITY; probes += 1 {
		if !occupied[slot] do return false
		if keys[slot] == value do return true
		slot = (slot + 1) % HASH_CAPACITY
	}
	return false
}

seen_add :: proc "contextless" (keys: [^]i64, occupied: [^]bool, value: i64) {
	slot := hash_slot(value)
	for probes := 0; probes < HASH_CAPACITY; probes += 1 {
		if !occupied[slot] { keys[slot] = value; occupied[slot] = true; return }
		if keys[slot] == value do return
		slot = (slot + 1) % HASH_CAPACITY
	}
}

already_output :: proc "contextless" (triples: [^]i64, count: int, a, b, c: i64) -> bool {
	for i := 0; i < count; i += 1 {
		if triples[i * 3] == a && triples[i * 3 + 1] == b && triples[i * 3 + 2] == c do return true
	}
	return false
}

write_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 { output[offset + byte] = u8((bits >> u32(byte * 8)) & 255) }
}

@(export)
find_triplets_with_0_sum_hashing :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_ITEMS || (length > 0 && input == nil) do return -1
	for i := c.size_t(0); i < length; i += 1 { if input[i] < -100000 || input[i] > 100000 do return -1 }
	triples: [MAX_TRIPLETS * 3]i64
	count := 0
	for i := 0; i + 2 < int(length); i += 1 {
		keys: [HASH_CAPACITY]i64
		occupied: [HASH_CAPACITY]bool = {}
		for j := i + 1; j < int(length); j += 1 {
			other := input[j]
			required := -input[i] - other
			if required >= -100000 && required <= 100000 && seen_contains(&keys[0], &occupied[0], required) {
				a, b, c := input[i], other, required
				if a > b { a, b = b, a }
				if b > c { b, c = c, b }
				if a > b { a, b = b, a }
				if !already_output(&triples[0], count, a, b, c) && count < MAX_TRIPLETS {
					triples[count * 3] = a; triples[count * 3 + 1] = b; triples[count * 3 + 2] = c
					count += 1
				}
			}
			seen_add(&keys[0], &occupied[0], other)
		}
	}
	if count == 0 do return 0
	needed := c.size_t(count * BYTES_PER_TRIPLET)
	if output == nil || output_capacity < needed do return -2
	for i := 0; i < count * 3; i += 1 { write_i32_le(output, i * 4, triples[i]) }
	return i64(count)
}
