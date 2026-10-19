package versabench_8b10b
import "core:c"

MAX_WORDS :: 160
MAX_OUTPUT_BYTES :: 18
RAW5 :: [32]u16{
	0x0d80, 0x05a2, 0x0c60, 0x0cc0, 0x0ca0, 0x10a2, 0x10c2, 0x10e0,
	0x0d20, 0x1122, 0x1142, 0x1160, 0x1182, 0x11a0, 0x11c0, 0x05e0,
	0x0e20, 0x1222, 0x1242, 0x1260, 0x1282, 0x12a0, 0x12c0, 0x06e0,
	0x1302, 0x1320, 0x1340, 0x0760, 0x0380, 0x07a0, 0x0e80, 0x06a2,
}
RAW3 :: [8]u16{0x0c08, 0x0c04, 0x1009, 0x100c, 0x1011, 0x1014, 0x0018, 0x041c}

encode_one :: proc(packed_word: u32, disparity: ^u32) -> u32 {
	data := packed_word & 0xff
	k := packed_word >> 8
	index5 := int(data >> 3)
	index3 := int(data & 7)
	lookup5 := u32(RAW5[index5])
	lookup3 := u32(RAW3[index3])
	if k == 1 && index5 == 7 do lookup5 = 0x04e2
	if k == 1 {
		if index3 >= 2 && index3 <= 5 { lookup3 = (lookup3 & ~u32(0x1000)) | 0x0800 }
		else if index3 == 7 do lookup3 = 0x040d
	}

	result: u32
	disparity1: u32
	if (lookup5 & 0x1000) != 0 {
		result = lookup5 & 0x03e2
		disparity1 = disparity^
	} else {
		code5 := lookup5 & 0x03e2
		plus5: u32 = 0
		flip5: u32 = 0
		if (lookup5 & 0x0800) != 0 do plus5 = 1
		if (lookup5 & 0x0400) != 0 do flip5 = 1
		if disparity^ == plus5 do result = code5 else result = code5 ^ 0x03e2
		disparity1 = disparity^ ^ flip5
	}

	if (lookup3 & 0x1000) != 0 {
		result |= lookup3 & 0x001d
		disparity^ = disparity1
	} else {
		code3 := lookup3 & 0x001d
		plus3: u32 = 0
		flip3: u32 = 0
		if (lookup3 & 0x0800) != 0 do plus3 = 1
		if (lookup3 & 0x0400) != 0 do flip3 = 1
		if disparity1 == plus3 do result |= code3 else result |= code3 ^ 0x001d
		disparity^ = disparity1 ^ flip3
	}
	return result
}

@(export, link_name="versabench_8b10b")
versabench_8b10b :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_WORDS || (length != 0 && values == nil) do return -1
	for index in 0..<length {
		if values[index] < 0 || values[index] > 511 do return -1
	}
	sample_count := c.size_t(0)
	if length > 0 do sample_count = 1 + (length - 1) / 128
	required := sample_count * 9
	if required != 0 && (output == nil || output_capacity < required) do return -2

	staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	disparity: u32 = 0
	hex := "0123456789ABCDEF"
	for pass_index in 0..<length {
		for index in 0..<length {
			encoded := encode_one(values[index].u32(), &disparity)
			if pass_index + 1 == length && index % 128 == 0 {
				for digit in 0..<8 {
					shift := u32((7 - digit) * 4)
					staged[used] = hex[int((encoded >> shift) & 15)]
					used += 1
				}
				staged[used] = '\n'
				used += 1
			}
		}
	}
	for index in 0..<required do output[index] = staged[index]
	return i64(used)
}
