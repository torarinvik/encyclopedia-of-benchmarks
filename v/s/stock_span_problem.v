module stock_span_problem

@[export: 'stock_span_problem']
pub fn stock_span_problem(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 66 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 1 || count_value > 64 { return -1 }
	count := int(count_value)
	if length != usize(count + 1) { return -1 }
	for day in 0 .. count {
		price := unsafe { input[day + 1] }
		if price < -2147483648 || price > 2147483647 { return -1 }
	}

	output_bytes := count * 8
	if output == nil || capacity < usize(output_bytes) { return -2 }
	mut decreasing := [64]usize{}
	mut top := 0
	for day in 0 .. count {
		price := unsafe { input[day + 1] }
		for top > 0 && unsafe { input[decreasing[top - 1] + 1] <= price } { top-- }
		span := if top == 0 { day + 1 } else { day - int(decreasing[top - 1]) }
		encoded := u64(span)
		for byte in 0 .. 8 {
			unsafe { output[day * 8 + byte] = u8((encoded >> (8 * byte)) & 255) }
		}
		decreasing[top] = usize(day)
		top++
	}
	return count_value
}
