module bitmap_block_allocation
const max_bits = 4096
const max_ops = 32
const max_output = max_bits / 8
@[export: 'bitmap_block_allocation']
pub fn bitmap_block_allocation(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > usize(2+2*max_ops) { return -1 }
		raw_bits := values[0]; raw_ops := values[1]
		if raw_bits < 1 || raw_bits > max_bits || raw_ops < 0 || raw_ops > max_ops || length != usize(2+2*int(raw_ops)) { return -1 }
		bits := int(raw_bits); ops := int(raw_ops)
		mut offsets := [max_ops]int{init: 0}; mut runs := [max_ops]int{init: 0}
		for i in 0 .. ops {
			o := values[2+2*i]; n := values[3+2*i]
			if o < 0 || o > raw_bits || n < 0 || n > raw_bits-o { return -1 }
			offsets[i] = int(o); runs[i] = int(n)
		}
		mut bitmap := [max_bits]bool{init: false}
		for b := 0; b < bits; b += 2 { bitmap[b] = true }
		for i in 0 .. ops {
			for b := offsets[i]; b < offsets[i]+runs[i]; b++ {
				if i % 3 == 0 { bitmap[b] = true } else if i % 3 == 1 { bitmap[b] = false } else { bitmap[b] = !bitmap[b] }
			}
		}
		byte_count := (bits+7)/8
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		for j in 0 .. byte_count {
			mut packed := u8(0)
			for bit in 0 .. 8 { index := j*8+bit; if index < bits && bitmap[index] { packed |= u8(1 << u32(bit)) } }
			output[j] = packed
		}
		return i64(byte_count)
	}
}
