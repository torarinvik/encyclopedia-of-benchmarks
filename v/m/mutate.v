module mutate

const max_genes = 64

@[export: 'mutate']
pub fn mutate(input &f64, length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 130 { return -1 }
		mu := input[0]
		count_value := input[1]
		if mu != mu || mu < 0.0 || mu > 1.0 { return -1 }
		if count_value != count_value || count_value < 0.0 || count_value > max_genes || count_value != f64(i64(count_value)) { return -1 }
		count := int(count_value)
		if int(length) != 2 + 2 * count { return -1 }
		for index in 0 .. count {
			gene := input[2 + index]
			if gene != 0.0 && gene != 1.0 { return -1 }
		}
		for index in 0 .. count {
			draw := input[2 + count + index]
			if draw != draw || draw < 0.0 || draw >= 1.0 { return -1 }
		}
		if output == nil || output_capacity < usize(count) { return -2 }
		for index in 0 .. count {
			gene := input[2 + index]
			draw := input[2 + count + index]
			output[index] = if draw < mu { 1.0 - gene } else { gene }
		}
		return i64(count)
	}
}
