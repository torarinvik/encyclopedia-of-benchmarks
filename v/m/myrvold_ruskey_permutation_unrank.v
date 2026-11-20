module myrvold_ruskey_permutation_unrank

@[export: 'myrvold_ruskey_permutation_unrank']
pub fn myrvold_ruskey_permutation_unrank(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 3 { return -1 }
	if length != 2 { return -1 }
	n_value := unsafe { input[0] }
	rank_value := unsafe { input[1] }
	if n_value < 0 || n_value > 8 || rank_value < 0 { return -1 }
	n := int(n_value)
	mut factorial := i64(1)
	mut factor := 2
	for factor <= n {
		factorial *= i64(factor)
		factor++
	}
	if rank_value >= factorial { return -1 }

	required := n * 8
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	mut permutation := [8]i64{}
	for i in 0 .. n { permutation[i] = i64(i) }
	mut remainder := rank_value
	mut size := n
	for size > 0 {
		choice := int(remainder % i64(size))
		remainder /= i64(size)
		held := permutation[size - 1]
		permutation[size - 1] = permutation[choice]
		permutation[choice] = held
		size--
	}
	for i in 0 .. n {
		value := u64(permutation[i])
		for byte in 0 .. 8 {
			unsafe { output[i * 8 + byte] = u8((value >> (byte * 8)) & 255) }
		}
	}
	return i64(required)
}
