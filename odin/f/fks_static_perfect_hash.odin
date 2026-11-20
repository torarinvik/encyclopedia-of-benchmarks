// Deterministic bounded two-level FKS static perfect hashing.
package fks_static_perfect_hash

import "core:c"

hash_index :: proc(a, b, modulus: int, key: i64) -> int {
	return ((a * int(key) + b) % 257) % modulus
}

@(export)
fks_static_perfect_hash :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 19 do return -1
	if input[0] < 0 || input[0] > 8 || input[1] < 0 || input[1] > 8 do return -1
	n := int(input[0])
	q := int(input[1])
	if int(length) != 2 + n + q do return -1
	for i := 0; i < n + q; i += 1 {
		if input[2 + i] < 0 || input[2 + i] > 255 do return -1
	}
	for i := 0; i < n; i += 1 {
		for j := i + 1; j < n; j += 1 {
			if input[2 + i] == input[2 + j] do return -1
		}
	}

	bucket_of: [8]int = {}
	bucket_sizes: [8]int = {}
	first_a, first_b := 0, 0
	first_found := n == 0
	for a := 1; a <= 256 && !first_found; a += 1 {
		for b := 0; b <= 256 && !first_found; b += 1 {
			counts: [8]int = {}
			for i := 0; i < n; i += 1 { counts[hash_index(a, b, n, input[2 + i])] += 1 }
		square_sum := 0
			for k := 0; k < n; k += 1 { square_sum += counts[k] * counts[k] }
			if square_sum <= 4 * n { first_a = a; first_b = b; first_found = true }
		}
	}
	if !first_found do return -1
	for i := 0; i < n; i += 1 {
		bucket_of[i] = hash_index(first_a, first_b, n, input[2 + i])
		bucket_sizes[bucket_of[i]] += 1
	}

	slot_keys: [8][64]i64 = {}
	occupied: [8][64]bool = {}
	local_a: [8]int = {}
	local_b: [8]int = {}
	for bucket := 0; bucket < n; bucket += 1 {
		count := bucket_sizes[bucket]
		if count == 0 do continue
		capacity := count * count
		local_found := false
		for a := 1; a <= 256 && !local_found; a += 1 {
			for b := 0; b <= 256 && !local_found; b += 1 {
				used: [64]bool = {}
				collision := false
				for i := 0; i < n; i += 1 {
					if bucket_of[i] == bucket {
						position := hash_index(a, b, capacity, input[2 + i])
						if used[position] { collision = true; break }
						used[position] = true
					}
				}
				if !collision {
					local_a[bucket] = a
					local_b[bucket] = b
					for i := 0; i < n; i += 1 {
						if bucket_of[i] == bucket {
							position := hash_index(a, b, capacity, input[2 + i])
							slot_keys[bucket][position] = input[2 + i]
							occupied[bucket][position] = true
						}
					}
					local_found = true
				}
			}
		}
		if !local_found do return -1
	}

	result: i64 = 0
	for i := 0; i < q; i += 1 {
		present := false
		if n > 0 {
			query := input[2 + n + i]
			bucket := hash_index(first_a, first_b, n, query)
			count := bucket_sizes[bucket]
			capacity := count * count
			if capacity > 0 {
				position := hash_index(local_a[bucket], local_b[bucket], capacity, query)
				present = occupied[bucket][position] && slot_keys[bucket][position] == query
			}
		}
		if present { result |= i64(1) << u32(i) }
	}
	return result
}
