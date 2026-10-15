module online_stock_span

@[export: 'online_stock_span']
pub fn online_stock_span(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 4095 { return -1 }
		count := int(input[0])
		if int(length) != count + 1 { return -1 }
		for day in 0 .. count {
			if input[day + 1] < 1 || input[day + 1] > 100000 { return -1 }
		}
		output_bytes := count * 8
		if int(output_capacity) < output_bytes { return -2 }
		mut decreasing := [4095]int{}
		mut top := 0
		for day in 0 .. count {
			price := input[day + 1]
			for top > 0 && input[decreasing[top - 1] + 1] <= price {
				top--
			}
			span := if top == 0 { day + 1 } else { day - decreasing[top - 1] }
			encoded := u64(span)
			for byte in 0 .. 8 {
				output[day * 8 + byte] = u8((encoded >> (byte * 8)) & 255)
			}
			decreasing[top] = day
			top++
		}
		return i64(count)
	}
}
