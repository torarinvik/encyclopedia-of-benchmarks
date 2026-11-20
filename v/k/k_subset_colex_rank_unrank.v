module k_subset_colex_rank_unrank

const max_n = 16
const max_k = 16
const max_input = 20

fn choose_small(n int, k_value int) i64 {
	if n < 0 || k_value < 0 || k_value > n { return 0 }
	mut k := k_value
	if k > n-k { k = n-k }
	mut value := i64(1)
	for i := 1; i <= k; i++ { value = value * i64(n-k+i) / i64(i) }
	return value
}

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[offset+byte] = u8((bits >> u64(8*byte)) & 255) }
	}
}

@[export: 'k_subset_colex_rank_unrank']
pub fn k_subset_colex_rank_unrank(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input { return -1 }
	unsafe {
		if length < 3 { return -1 }
		mode := input[0]
		if mode != 0 && mode != 1 { return -1 }
		raw_n, raw_k := input[1], input[2]
		if raw_n < 0 || raw_n > max_n || raw_k < 0 || raw_k > raw_n { return -1 }
		n, k := int(raw_n), int(raw_k)
		mut indices := [max_k]i64{}
		mut rank := i64(0)
		if mode == 0 {
			if int(length) != 3+k { return -1 }
			for i in 0 .. k {
				index := input[3+i]
				if index < 0 || index >= raw_n || (i > 0 && indices[i-1] >= index) { return -1 }
				indices[i] = index
				rank += choose_small(int(index), i+1)
			}
		} else {
			if length != 4 { return -1 }
			rank = input[3]
			if rank < 0 || rank >= choose_small(n, k) { return -1 }
			mut upper := n-1
			mut remaining := rank
			for order := k; order >= 1; order-- {
				mut candidate := upper
				for candidate >= 0 && choose_small(candidate, order) > remaining { candidate-- }
				if candidate < 0 { return -1 }
				indices[order-1] = i64(candidate)
				remaining -= choose_small(candidate, order)
				upper = candidate-1
			}
		}
		needed := usize((k+1)*8)
		if output == nil || capacity < needed { return -2 }
		store_i64_le(output, 0, rank)
		for i in 0 .. k { store_i64_le(output, (i+1)*8, indices[i]) }
		return i64(needed)
	}
}
