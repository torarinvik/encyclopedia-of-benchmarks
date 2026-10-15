package sock_merchant

import "core:c"

@(export)
sock_merchant :: proc "c" (colors: [^]i64, length: c.size_t) -> i64 {
	if length > 512 do return -1
	counts: [4096]u64
	for color := 0; color < 4096; color += 1 { counts[color] = 0 }
	for index := c.size_t(0); index < length; index += 1 {
		value := colors[index]
		if value < 0 || value > 4095 do return -1
		counts[int(value)] += 1
	}
	pairs := u64(0)
	for color := 0; color < 4096; color += 1 { pairs += counts[color] / 2 }
	return i64(pairs)
}
