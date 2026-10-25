module tsvc_s424_alias_overlap_feedback

const max_n = 192
const x_length = max_n + 63
const max_input_length = max_n + 64

@[export: 'tsvc_s424_alias_overlap_feedback']
pub fn tsvc_s424_alias_overlap_feedback(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 130 || length > max_input_length { return -1 }
		if input[0] < 66 || input[0] > max_n { return -1 }
		n := int(input[0])
		if int(length) != n + 64 { return -1 }
		mut a := [max_n]i64{}
		mut x := [x_length]i64{}
		for i in 0 .. n {
			a[i] = input[1 + i]
			if a[i] < 0 || a[i] > 10 { return -1 }
		}
		for i in 0 .. 63 {
			x[i] = input[1 + n + i]
			if x[i] < 0 || x[i] > 10 { return -1 }
		}
		for i in 63 .. x_length { x[i] = 0 }
		for i in 0 .. n - 1 { x[i + 64] = x[i] + a[i] }
		mut checksum := i64(0)
		for i in 0 .. n { checksum += x[63 + i] }
		return checksum
	}
}
