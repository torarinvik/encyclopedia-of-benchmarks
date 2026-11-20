module k_inverse_pairs_array

const max_n = 128
const max_k = 512
const modulus = i64(1_000_000_007)

@[export: 'k_inverse_pairs_array']
pub fn k_inverse_pairs_array(input &i64, length usize) i64 {
	if length < 1 || length > 3 || length != 2 { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value := input[0]
		k_value := input[1]
		if n_value < 0 || n_value > max_n || k_value < 0 || k_value > max_k { return -1 }
		n := int(n_value)
		k := int(k_value)
		max_inversions := 0
		if n > 0 { max_inversions = n * (n - 1) / 2 }
		if k > max_inversions { return 0 }

		mut previous := [max_k + 1]i64{}
		mut current := [max_k + 1]i64{}
		previous[0] = 1
		for size in 1 .. n + 1 {
			mut window := i64(0)
			for inversions in 0 .. k + 1 {
				window += previous[inversions]
				if inversions >= size { window -= previous[inversions - size] }
				window %= modulus
				if window < 0 { window += modulus }
				current[inversions] = window
			}
			previous = current
			current = [max_k + 1]i64{}
		}
		return previous[k]
	}
}
