package hyper_log_log

import "core:c"
import "core:math"

@(export)
hyper_log_log :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 1025 do return -1
	count64 := input[0]
	if count64 < 1 || count64 > 1024 || length != c.size_t(count64 + 1) do return -1
	count := int(count64)
	for i := 0; i < count; i += 1 { if input[1+i] < 1 || input[1+i] > 65535 do return -1 }

	var registers: [65536]u8
	var seen: [65536]u8
	var touched: [1024]u16
	for i := 0; i < 65536; i += 1 { registers[i] = 0; seen[i] = 0 }
	touched_count := 0
	for i := 0; i < count; i += 1 {
		value := u32(input[1+i])
		bits := value
		rank := u8(0)
		for (bits & 1) == 0 { rank += 1; bits >>= 1 }
		index := int(value)
		if seen[index] == 0 { seen[index] = 1; touched[touched_count] = u16(value); touched_count += 1 }
		if rank > registers[index] do registers[index] = rank
	}

	z := f64(0)
	for i := 0; i < touched_count; i += 1 { z += 1.0 / f64(u32(1) << u32(registers[int(touched[i])])) }
	k := f64(touched_count)
	return i64(math.ceil(0.673 * k * (k / z)))
}
