// Deterministic bounded two-level FKS static perfect hashing.
module fks_static_perfect_hash

fn hash_index(a int, b int, modulus int, key i64) int {
	return ((a * int(key) + b) % 257) % modulus
}

@[export: 'fks_static_perfect_hash']
pub fn fks_static_perfect_hash(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 19 { return -1 }
		if input[0] < 0 || input[0] > 8 || input[1] < 0 || input[1] > 8 { return -1 }
		n := int(input[0])
		q := int(input[1])
		if int(length) != 2 + n + q { return -1 }
		for i in 0 .. n + q {
			if input[2 + i] < 0 || input[2 + i] > 255 { return -1 }
		}
		for i in 0 .. n {
			for j in i + 1 .. n {
				if input[2 + i] == input[2 + j] { return -1 }
			}
		}

		mut bucket_of := [8]int{}
		mut bucket_sizes := [8]int{}
		mut first_a := 0
		mut first_b := 0
		mut first_found := n == 0
		for a in 1 .. 257 {
			if first_found { break }
			for b in 0 .. 257 {
				if first_found { break }
				mut counts := [8]int{}
				for i in 0 .. n { counts[hash_index(a, b, n, input[2 + i])]++ }
				mut square_sum := 0
				for bucket in 0 .. n { square_sum += counts[bucket] * counts[bucket] }
				if square_sum <= 4 * n {
					first_a = a
					first_b = b
					first_found = true
				}
			}
		}
		if !first_found { return -1 }
		for i in 0 .. n {
			bucket_of[i] = hash_index(first_a, first_b, n, input[2 + i])
			bucket_sizes[bucket_of[i]]++
		}

		mut slot_keys := [8][64]i64{}
		mut occupied := [8][64]bool{}
		mut local_a := [8]int{}
		mut local_b := [8]int{}
		for bucket in 0 .. n {
			count := bucket_sizes[bucket]
			if count == 0 { continue }
			capacity := count * count
			mut local_found := false
			for a in 1 .. 257 {
				if local_found { break }
				for b in 0 .. 257 {
					if local_found { break }
					mut used := [64]bool{}
					mut collision := false
					for i in 0 .. n {
						if bucket_of[i] == bucket {
							position := hash_index(a, b, capacity, input[2 + i])
							if used[position] { collision = true; break }
							used[position] = true
						}
					}
					if !collision {
						local_a[bucket] = a
						local_b[bucket] = b
						for i in 0 .. n {
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
			if !local_found { return -1 }
		}

		mut result := i64(0)
		for i in 0 .. q {
			mut present := false
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
}
