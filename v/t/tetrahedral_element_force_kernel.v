module tetrahedral_element_force_kernel

const max_elements = 32
const max_valid_input = 3 + 12 * max_elements
const max_input = max_valid_input + 1
const max_output = 3072

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tetrahedral_element_force_kernel']
pub fn tetrahedral_element_force_kernel(input &i64, length usize,
		mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		m_value, lambda, mu := input[0], input[1], input[2]
		if m_value < 1 || m_value > max_elements || lambda < 0 || lambda > 16 ||
			mu < 0 || mu > 16 || length != usize(3 + 12*m_value) { return -1 }
		m := int(m_value)
		for i in 3 .. int(length) {
			if input[i] < -4 || input[i] > 4 { return -1 }
		}

		required := 96 * m
		if output == nil || capacity < usize(required) { return -2 }
		mut staged := [max_output]u8{}
		for element in 0 .. m {
			base := 3 + 12*element
			mut deformation := [9]i64{}
			for row in 0 .. 3 {
				for column in 0 .. 3 {
					deformation[row*3+column] = input[base+3*(column+1)+row] - input[base+row]
				}
			}
			trace_delta := deformation[0] + deformation[4] + deformation[8] - 3
			mut stress := [9]i64{}
			for row in 0 .. 3 {
				for column in 0 .. 3 {
					diagonal := i64(0)
					if row == column { diagonal = 1 }
					stress[row*3+column] = lambda*trace_delta*diagonal +
						mu*(deformation[row*3+column]+deformation[column*3+row]-2*diagonal)
				}
			}
			for axis in 0 .. 3 {
				vertex_zero := stress[axis*3] + stress[axis*3+1] + stress[axis*3+2]
				store_i64_le(mut &staged[0], 8*(12*element+axis), vertex_zero)
				for vertex in 1 .. 4 {
					store_i64_le(mut &staged[0], 8*(12*element+3*vertex+axis),
						-stress[axis*3+vertex-1])
				}
			}
		}
		for i in 0 .. required { output[i] = staged[i] }
		return i64(required)
	}
}
