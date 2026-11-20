const max_h = 32
const max_w = 32
const max_q = 128
const max_input = 1540
const max_output = 1024
const modulus = i64(1_000_000_007)
const row_base = i64(31)
const col_base = i64(37)

@[export: 'rolling_hash_2d_rectangle_query']
pub fn rolling_hash_2d_rectangle_query(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		h_value := input[0]
		w_value := input[1]
		q_value := input[2]
		if h_value < 1 || h_value > max_h || w_value < 1 || w_value > max_w || q_value < 1 || q_value > max_q { return -1 }
		h := int(h_value)
		w := int(w_value)
		q := int(q_value)
		if length != usize(3 + h*w + 4*q) { return -1 }
		query_offset := 3 + h*w
		for i in 0 .. h*w {
			if input[3+i] < 0 || input[3+i] > 255 { return -1 }
		}
		for i in 0 .. q {
			r0 := input[query_offset + 4*i]
			c0 := input[query_offset + 4*i + 1]
			r1 := input[query_offset + 4*i + 2]
			c1 := input[query_offset + 4*i + 3]
			if r0 < 0 || r0 > r1 || r1 > h_value || c0 < 0 || c0 > c1 || c1 > w_value { return -1 }
		}
		required := 8*q
		if output == nil || capacity < usize(required) { return -2 }

		mut row_power := [max_h + 1]i64{}
		mut col_power := [max_w + 1]i64{}
		row_power[0] = 1
		col_power[0] = 1
		for i in 1 .. h+1 { row_power[i] = row_power[i-1] * row_base % modulus }
		for j in 1 .. w+1 { col_power[j] = col_power[j-1] * col_base % modulus }
		mut prefix := [max_h + 1][max_w + 1]i64{}
		for r in 1 .. h+1 {
			mut row_hash := i64(0)
			for c in 1 .. w+1 {
				row_hash = (row_hash * col_base + input[3 + (r-1)*w + c-1]) % modulus
				prefix[r][c] = (prefix[r-1][c] * row_base + row_hash) % modulus
			}
		}
		mut staged := [max_output]u8{}
		for i in 0 .. q {
			r0 := int(input[query_offset + 4*i])
			c0 := int(input[query_offset + 4*i + 1])
			r1 := int(input[query_offset + 4*i + 2])
			c1 := int(input[query_offset + 4*i + 3])
			rh := r1-r0
			cw := c1-c0
			mut value := prefix[r1][c1] - prefix[r0][c1] * row_power[rh] % modulus -
				prefix[r1][c0] * col_power[cw] % modulus +
				prefix[r0][c0] * row_power[rh] % modulus * col_power[cw] % modulus
			value %= modulus
			if value < 0 { value += modulus }
			bits := u64(value)
			for byte in 0 .. 8 { staged[8*i+byte] = u8((bits >> (8*byte)) & 255) }
		}
		for i in 0 .. required { output[i] = staged[i] }
		return i64(required)
	}
}
