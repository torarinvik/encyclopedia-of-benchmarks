package shootout_hash

foreign import libc "system:c"
foreign libc {
	calloc :: proc "c" (count, size: uintptr) -> rawptr ---
	free :: proc "c" (memory: rawptr) ---
}

MAX_N :: i64(3_500_000)
BUCKET_PRIMES := [28]u32{
	53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593,
	49157, 98317, 196613, 393241, 786433, 1572869, 3145739,
	6291469, 12582917, 25165843, 50331653, 100663319, 201326611,
	402653189, 805306457, 1610612741, 3221225473, 4294967291,
}

bucket_count_for :: proc "contextless" (n: u32) -> int {
	for prime in BUCKET_PRIMES {
		if prime >= n do return int(prime)
	}
	return int(BUCKET_PRIMES[len(BUCKET_PRIMES)-1])
}

hash_key :: proc "contextless" (value_input, base: u32, bucket_count: int) -> int {
	value := value_input
	reverse: [16]u8
	length := 0
	for {
		digit := value % base
		reverse[length] = u8(48 + digit if digit < 10 else 87 + digit)
		length += 1
		value /= base
		if value == 0 do break
	}
	hash: u64 = 0
	for length > 0 {
		length -= 1
		hash = 5 * hash + u64(reverse[length])
	}
	return int(hash % u64(bucket_count))
}

hex_key_matches_decimal :: proc "contextless" (hex_value_input, decimal_value_input: u32) -> bool {
	hex_value, decimal_value := hex_value_input, decimal_value_input
	for hex_value != 0 && decimal_value != 0 {
		digit := hex_value & 15
		if digit >= 10 || digit != decimal_value % 10 do return false
		hex_value >>= 4
		decimal_value /= 10
	}
	return hex_value == 0 && decimal_value == 0
}

@(export, link_name="shootout_hash")
shootout_hash :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > MAX_N do return -1
	bound := u32(n)
	bucket_count := bucket_count_for(bound)
	heads := cast([^]u32)calloc(uintptr(bucket_count), size_of(u32))
	next := cast([^]u32)calloc(uintptr(bound)+1, size_of(u32))
	defer free(heads)
	defer free(next)
	if heads == nil || next == nil do return -1

	value: u32 = 1
	for value <= bound {
		bucket := hash_key(value, 16, bucket_count)
		node := heads[bucket]
		previous: u32 = 0
		for node != 0 {
			if node == value do break
			previous = node
			node = next[int(node)]
		}
		if node == 0 {
			if previous == 0 {
				heads[bucket] = value
			} else {
				next[int(previous)] = value
			}
		}
		value += 1
	}

	found: i64 = 0
	value = bound
	for value > 0 {
		bucket := hash_key(value, 10, bucket_count)
		node := heads[bucket]
		for node != 0 {
			if hex_key_matches_decimal(node, value) {
				found += 1
				break
			}
			node = next[int(node)]
		}
		value -= 1
	}
	return found
}
