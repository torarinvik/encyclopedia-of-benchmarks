// Clean-room port of TSVC s1281; see the package README for provenance and rights.

const max_n = 16
const max_input_length = 82

fn store_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'tsvc_s1281_elementwise_dual_update']
pub fn tsvc_s1281_elementwise_dual_update(input &i64, input_length usize,
	output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 7 || input_length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	passes_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || passes_value < 1 || passes_value > 8 { return -1 }
	n := int(n_value)
	passes := int(passes_value)
	if input_length != usize(2 + 5 * n) { return -1 }

	mut a := [max_n]f64{}
	mut b := [max_n]f64{}
	mut c_values := [max_n]f64{}
	mut d_values := [max_n]f64{}
	mut e_values := [max_n]f64{}
	for i in 0 .. n {
		av := unsafe { input[2 + i] }
		bv := unsafe { input[2 + n + i] }
		cv := unsafe { input[2 + 2 * n + i] }
		dv := unsafe { input[2 + 3 * n + i] }
		ev := unsafe { input[2 + 4 * n + i] }
		if av < -1 || av > 1 || bv < -1 || bv > 1 || cv < -1 || cv > 1 || dv < -1 || dv > 1 || ev < -1 || ev > 1 { return -1 }
		a[i] = f64(av); b[i] = f64(bv); c_values[i] = f64(cv)
		d_values[i] = f64(dv); e_values[i] = f64(ev)
	}

	output_bytes := 16 * n
	if unsafe { output == nil } || output_capacity < usize(output_bytes) { return -2 }
	for _ in 0 .. passes {
		for i in 0 .. n {
			x := b[i] * c_values[i] + a[i] * d_values[i] + e_values[i]
			a[i] = x - 1.0
			b[i] = x
		}
	}
	for i in 0 .. n {
		store_i64_le(output, 8*i, i64(a[i]))
		store_i64_le(output, 8*(n+i), i64(b[i]))
	}
	return i64(output_bytes)
}
