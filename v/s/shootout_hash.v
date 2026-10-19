module shootout_hash

const max_n = i64(3500000)
const bucket_primes = [28]u32{
	53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593,
	49157, 98317, 196613, 393241, 786433, 1572869, 3145739,
	6291469, 12582917, 25165843, 50331653, 100663319, 201326611,
	402653189, 805306457, 1610612741, 3221225473, 4294967291,
}

fn bucket_count_for(n u32) int {
	for prime in bucket_primes {
		if prime >= n { return int(prime) }
	}
	return int(bucket_primes[bucket_primes.len - 1])
}

fn hash_key(value_input u32, base u32, bucket_count int) int {
	mut value := value_input
	mut reverse := [16]u8{}
	mut length := 0
	for {
		digit := value % base
		reverse[length] = u8(if digit < 10 { 48 + digit } else { 87 + digit })
		length++
		value /= base
		if value == 0 { break }
	}
	mut hash := u64(0)
	for length > 0 {
		length--
		hash = 5 * hash + u64(reverse[length])
	}
	return int(hash % u64(bucket_count))
}

fn hex_key_matches_decimal(hex_value_input u32, decimal_value_input u32) bool {
	mut hex_value := hex_value_input
	mut decimal_value := decimal_value_input
	for hex_value != 0 && decimal_value != 0 {
		digit := hex_value & 15
		if digit >= 10 || digit != decimal_value % 10 { return false }
		hex_value >>= 4
		decimal_value /= 10
	}
	return hex_value == 0 && decimal_value == 0
}

@[export: 'shootout_hash']
pub fn shootout_hash(n i64) i64 {
	if n < 0 || n > max_n { return -1 }
	bound := u32(n)
	bucket_count := bucket_count_for(bound)
	mut heads := []u32{len: bucket_count}
	defer { heads.free() }
	mut next := []u32{len: int(bound) + 1}
	defer { next.free() }

	mut value := u32(1)
	for value <= bound {
		bucket := hash_key(value, 16, bucket_count)
		mut node := heads[bucket]
		mut previous := u32(0)
		for node != 0 {
			if node == value { break }
			previous = node
			node = next[int(node)]
		}
		if node == 0 {
			if previous == 0 { heads[bucket] = value }
			else { next[int(previous)] = value }
		}
		value++
	}

	mut found := i64(0)
	value = bound
	for value > 0 {
		bucket := hash_key(value, 10, bucket_count)
		mut node := heads[bucket]
		for node != 0 {
			if hex_key_matches_decimal(node, value) {
				found++
				break
			}
			node = next[int(node)]
		}
		value--
	}
	return found
}
