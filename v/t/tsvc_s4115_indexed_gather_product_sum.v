module tsvc_s4115_indexed_gather_product_sum

const max_n = 64
const max_input_length = 193

@[export: 'tsvc_s4115_indexed_gather_product_sum']
pub fn tsvc_s4115_indexed_gather_product_sum(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	unsafe {
		n_raw := input[0]
		if n_raw < 1 || n_raw > max_n { return -1 }
		n := int(n_raw)
		if length != usize(1 + 3 * n) { return -1 }
		for i in 0 .. n {
			index := input[1 + i]
			a_value := input[1 + n + i]
			b_value := input[1 + 2 * n + i]
			if index < 0 || index >= n_raw { return -1 }
			if a_value < 0 || a_value > 1_000_000 || b_value < 0 || b_value > 1_000_000 { return -1 }
		}
		mut total := i64(0)
		for i in 0 .. n {
			index := int(input[1 + i])
			total += input[1 + n + i] * input[1 + 2 * n + index]
		}
		return total
	}
}
