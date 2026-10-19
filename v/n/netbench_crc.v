module netbench_crc

const max_length = usize(256)
const polynomial = u64(0x04c11db7)
const output_mask = u64(0xffffffff)

@[export: 'netbench_crc']
pub fn netbench_crc(values &i64, length usize) i64 {
	if length > max_length || (length > 0 && unsafe { values == nil }) { return -1 }
	unsafe {
		for index in 0 .. int(length) {
			if values[index] < 0 || values[index] > 255 { return -1 }
		}
	}

	mut table := [256]u64{}
	for byte in 0 .. 256 {
		mut remainder := u64(byte) << 24
		for _ in 0 .. 8 {
			if (remainder & u64(0x80000000)) != 0 {
				remainder = (remainder << 1) ^ polynomial
			} else {
				remainder <<= 1
			}
		}
		table[byte] = remainder
	}

	mut crc := u64(0)
	unsafe {
		for index in 0 .. int(length) {
			byte := u64(values[index])
			table_index := int(((crc >> 24) ^ byte) & u64(0xff))
			crc = (crc << 8) ^ table[table_index]
		}
	}
	return i64(crc & output_mask)
}
