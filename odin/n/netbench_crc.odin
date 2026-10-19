package netbench_crc

import "core:c"

MAX_LENGTH :: c.size_t(256)
POLYNOMIAL :: u64(0x04c11db7)
OUTPUT_MASK :: u64(0xffffffff)

@(export)
netbench_crc :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && values == nil) do return -1
	for index: c.size_t = 0; index < length; index += 1 {
		if values[index] < 0 || values[index] > 255 do return -1
	}

	var table: [256]u64
	for byte: u64 = 0; byte < 256; byte += 1 {
		remainder := byte << 24
		for bit := 0; bit < 8; bit += 1 {
			if (remainder & u64(0x80000000)) != 0 do remainder = (remainder << 1) ^ POLYNOMIAL
			else remainder = remainder << 1
		}
		table[int(byte)] = remainder
	}

	crc := u64(0)
	for index: c.size_t = 0; index < length; index += 1 {
		byte := u64(values[index])
		table_index := int(((crc >> 24) ^ byte) & u64(0xff))
		crc = (crc << 8) ^ table[table_index]
	}
	return i64(crc & OUTPUT_MASK)
}
