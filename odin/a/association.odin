package association

import "core:c"

popcount :: proc "contextless" (value_in: u64) -> int {
	value := value_in
	count := 0
	for value != 0 { count += int(value & 1); value >>= 1 }
	return count
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
	bits := transmute(u64)value
	for b: usize = 0; b < 8; b += 1 { output[offset+b] = u8(bits >> u64(8*b)) }
}

@(export)
association :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 11 do return -1
	transactions, items := usize(input[0]), usize(input[1])
	if length != 2+transactions do return -1
	limit := u64(1) << items
	valid_bits := limit-1
	for t: usize = 0; t < transactions; t += 1 { if input[2+t] < 0 || u64(input[2+t]) > valid_bits do return -1 }
	frequent: [2048]bool
	masks: [2047]i64
	supports: [2047]i64
	count: usize = 0
	for set_size: usize = 1; set_size <= items; set_size += 1 {
		for mask: u64 = 1; mask < limit; mask += 1 {
			if popcount(mask) != int(set_size) do continue
			if set_size > 1 {
				ok := true
				for bit: usize = 0; bit < items; bit += 1 { bit_mask := u64(1) << bit; if (mask & bit_mask) != 0 && !frequent[mask ^ bit_mask] do ok = false }
				if !ok do continue
			}
			support: i64 = 0
			for t: usize = 0; t < transactions; t += 1 { if (u64(input[2+t]) & mask) == mask do support += 1 }
			if support > 0 { frequent[mask] = true; masks[count] = i64(mask); supports[count] = support; count += 1 }
		}
	}
	required := count*16
	if capacity < required || (required > 0 && output == nil) do return -2
	for i: usize = 0; i < count; i += 1 { put_i64_le(output,i*16,masks[i]); put_i64_le(output,i*16+8,supports[i]) }
	return i64(required)
}
