module morton_sort

type I64Input = &i64
type U8Output = &u8

fn spread_16(value_in u32) u32 {
	mut value := value_in
	value = (value | (value << 8)) & 0x00ff00ff
	value = (value | (value << 4)) & 0x0f0f0f0f
	value = (value | (value << 2)) & 0x33333333
	return (value | (value << 1)) & 0x55555555
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'morton_sort']
pub fn morton_sort(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 3 || length > 513 { return -1 }
		raw_count := values[0]
		if raw_count < 1 || raw_count > 256 { return -1 }
		count := int(raw_count)
		if length != usize(1 + 2 * count) { return -1 }
		mut keys := []u32{len: count, init: 0}
		mut order := []int{len: count, init: 0}
		for index in 0 .. count {
			x, y := values[1 + 2 * index], values[2 + 2 * index]
			if x < 0 || x > 65535 || y < 0 || y > 65535 { return -1 }
			keys[index] = spread_16(u32(x)) | (spread_16(u32(y)) << 1)
			order[index] = index
		}
		bytes := count * 8
		if output == nil || output_capacity < usize(bytes) { return -2 }
		for index in 1 .. count {
			current := order[index]
			mut position := index
			for position > 0 && (keys[order[position - 1]] > keys[current] ||
				(keys[order[position - 1]] == keys[current] && order[position - 1] > current)) {
				order[position] = order[position - 1]
				position--
			}
			order[position] = current
		}
		for index in 0 .. count { store_i64_le(mut output, index * 8, i64(order[index])) }
		return i64(bytes)
	}
}
