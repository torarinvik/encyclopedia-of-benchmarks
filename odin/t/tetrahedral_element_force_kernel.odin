package tetrahedral_element_force_kernel

import "core:c"

MAX_ELEMENTS :: 32
MAX_VALID_INPUT :: 3 + 12*MAX_ELEMENTS
MAX_INPUT :: MAX_VALID_INPUT + 1
MAX_OUTPUT :: 3072

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
tetrahedral_element_force_kernel :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	m_value, lambda, mu := input[0], input[1], input[2]
	if m_value < 1 || m_value > MAX_ELEMENTS || lambda < 0 || lambda > 16 ||
		mu < 0 || mu > 16 || length != c.size_t(3 + 12*m_value) do return -1
	m := int(m_value)
	for i := 3; i < int(length); i += 1 {
		if input[i] < -4 || input[i] > 4 do return -1
	}

	required := c.size_t(96 * m)
	if output == nil || capacity < required do return -2
	staged: [MAX_OUTPUT]u8 = {}
	for element := 0; element < m; element += 1 {
		base := 3 + 12*element
		f: [9]i64
		for row := 0; row < 3; row += 1 {
			for column := 0; column < 3; column += 1 {
				f[row*3+column] = input[base+3*(column+1)+row] - input[base+row]
			}
		}
		trace_delta := f[0] + f[4] + f[8] - 3
		stress: [9]i64
		for row := 0; row < 3; row += 1 {
			for column := 0; column < 3; column += 1 {
				diagonal := i64(0)
				if row == column do diagonal = 1
				stress[row*3+column] = lambda*trace_delta*diagonal +
					mu*(f[row*3+column]+f[column*3+row]-2*diagonal)
			}
		}
		for axis := 0; axis < 3; axis += 1 {
			vertex0 := stress[axis*3] + stress[axis*3+1] + stress[axis*3+2]
			store_i64_le(&staged[0], 8*(12*element+axis), vertex0)
			for vertex := 1; vertex < 4; vertex += 1 {
				store_i64_le(&staged[0], 8*(12*element+3*vertex+axis),
					-stress[axis*3+vertex-1])
			}
		}
	}
	for i := 0; i < int(required); i += 1 { output[i] = staged[i] }
	return i64(required)
}
