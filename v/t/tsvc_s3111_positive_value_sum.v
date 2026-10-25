module tsvc_s3111_positive_value_sum

const max_n = 64
const max_input_length = 1 + max_n
const max_value = i64(1_000_000)

@[export: 'tsvc_s3111_positive_value_sum']
pub fn tsvc_s3111_positive_value_sum(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 0 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 1 + n { return -1 }

	mut sum := i64(0)
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < -max_value || value > max_value { return -1 }
		if value > 0 { sum += value }
	}
	return sum
}
