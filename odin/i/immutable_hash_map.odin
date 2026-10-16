package immutable_hash_map

import "core:c"

FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

hash_i64 :: proc(hash: u64, value: i64) -> u64 {
	result := hash
	bits := transmute(u64(value))
	for shift := 0; shift < 64; shift += 8 { result = (result ^ u64(u8(bits >> u64(shift)))) * FNV_PRIME }
	return result
}

@(export)
immutable_hash_map :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 769 do return -1
	count64 := input[0]
	if count64 < 0 || count64 > 256 || length != c.size_t(1 + 3 * count64) do return -1
	count := int(count64)
	var keys: [256]i32
	var values: [256]i32
	var trace: [256]i64
	map_size := 0
	for i := 0; i < count; i += 1 {
		operation, key64, value64 := input[1+3*i], input[2+3*i], input[3+3*i]
		if operation < 0 || operation > 3 || key64 < -2147483648 || key64 > 2147483647 || value64 < -2147483648 || value64 > 2147483647 do return -1
		key, value := i32(key64), i32(value64)
		if operation == 0 {
			if value == 0 do return -1
			keys[map_size] = key; values[map_size] = value; map_size += 1
			trace[i] = i64(map_size)
		} else if operation == 1 || operation == 2 {
			found_value: i32 = 0
			for j := map_size; j > 0; j -= 1 {
				if keys[j-1] == key { found_value = values[j-1]; break }
			}
			if operation == 1 { trace[i] = i64(found_value) }
			else if found_value != 0 { trace[i] = 1 }
			else { trace[i] = 0 }
		} else {
			trace[i] = i64(map_size)
		}
	}
	hash := hash_i64(FNV_OFFSET, count64)
	for i := 0; i < count; i += 1 { hash = hash_i64(hash, trace[i]) }
	return i64(hash & 0x7fffffffffffffff)
}
