module cbench_consumer_mad_alias_reduce

const cs = [8]i64{0x0db84a81, 0x0e1b9d7f, 0x0f31adcf, 0x0fbba815, 0x0feda417, 0x0ffc8fc8, 0x0fff964c, 0x0ffff8d3}
const ca = [8]i64{-0x083b5fe7, -0x078c36d2, -0x05039814, -0x02e91dd1, -0x0183603a, -0x00a7cb87, -0x003a2847, -0x000f27b4}

fn floor_div(value i64, divisor i64) i64 {
	quotient := value / divisor
	if value % divisor < 0 { return quotient - 1 }
	return quotient
}

fn mad_mul(left i64, right i64) i64 {
	return floor_div(left + 2048, 4096) * floor_div(right + 32768, 65536)
}

fn put_i32_le(mut output &u8, offset int, value i64) {
	for byte in 0 .. 4 {
		shifted := floor_div(value, i64(1) << (8 * byte))
		part := shifted % 256
		if part < 0 { part += 256 }
		unsafe { output[offset + byte] = u8(part) }
	}
}

@[export: 'cbench_consumer_mad_alias_reduce']
fn cbench_consumer_mad_alias_reduce(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 65 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 4 { return -1 }
		boundaries := int(input[0])
		if length != usize(1 + 16 * boundaries) { return -1 }
		for i in 1 .. int(length) { if input[i] < -100_000_000 || input[i] > 100_000_000 { return -1 } }
		output_size := 64 * boundaries
		mut staged := [64]i64{}
		for boundary in 0 .. boundaries {
			base := 1 + 16 * boundary
			for i in 0 .. 8 {
				a, b := input[base + 2 * i], input[base + 2 * i + 1]
				staged[16 * boundary + 2 * i] = mad_mul(a, cs[i]) + mad_mul(-b, ca[i])
				staged[16 * boundary + 2 * i + 1] = mad_mul(b, cs[i]) + mad_mul(a, ca[i])
			}
		}
		if unsafe { output == nil } || capacity < usize(output_size) { return -2 }
		for i in 0 .. 16 * boundaries { put_i32_le(output, 4 * i, staged[i]) }
		return i64(output_size)
	}
}
