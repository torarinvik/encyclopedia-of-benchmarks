module main

const max_steps = 8
const max_input = 18
const max_bid = 16
const max_output = 16

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for b in 0 .. 8 { output[offset+b] = u8((bits >> (b*8)) & 255) } }
}

@[export: 'single_parameter_truthful_payment']
pub fn single_parameter_truthful_payment(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 4 || length > max_input { return -1 }
		if values[0] < 0 || values[0] > max_bid || values[1] < 1 || values[1] > max_steps { return -1 }
		bid, k := int(values[0]), int(values[1])
		if length != usize(2+2*k) { return -1 }
		for i in 0 .. k {
			point, load := values[2+2*i], values[3+2*i]
			if point < 0 || point >= max_bid || load < 0 || load > max_bid { return -1 }
			if i == 0 && point != 0 { return -1 }
			if i > 0 && (point <= values[2+2*(i-1)] || load > values[3+2*(i-1)]) { return -1 }
		}
		mut allocation := i64(0)
		if bid < max_bid { for i in 0 .. k { if int(values[2+2*i]) <= bid { allocation = values[3+2*i] } } }
		mut area := i64(0)
		for i in 0 .. k {
			start := int(values[2+2*i])
			finish := if i+1 < k { int(values[2+2*(i+1)]) } else { max_bid }
			left := if start > bid { start } else { bid }
			if finish > left { area += i64(finish-left) * values[3+2*i] }
		}
		payment := i64(bid)*allocation + area
		if output == nil || capacity < max_output { return -2 }
		mut staged := [16]u8{}
		put_i64(mut staged[0], 0, allocation)
		put_i64(mut staged[0], 8, payment)
		for i in 0 .. max_output { output[i] = staged[i] }
		return max_output
	}
}
