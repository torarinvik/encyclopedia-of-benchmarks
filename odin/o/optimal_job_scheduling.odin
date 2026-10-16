package optimal_job_scheduling

import "core:c"

append_uint :: proc(b: [^]u8, used: ^int, value: int) {
	digits: [12]u8
	count := 0
	x := value
	if x == 0 { b[used^] = '0'; used^ += 1; return }
	for x > 0 { digits[count] = u8('0' + x%10); count += 1; x /= 10 }
	for count > 0 { count -= 1; b[used^] = digits[count]; used^ += 1 }
}
@(export)
optimal_job_scheduling :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > 194 || values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 8 do return -1
	p := int(values[0]); m := int(values[1]); if int(length) != 2+p*m+m*m do return -1
	for i := 2; i < int(length); i += 1 { if values[i] < 0 || values[i] > 1000 do return -1 }
	cost: [128]int
	for j := 0; j < m; j += 1 { cost[j] = int(values[2+j]) }
	for i := 1; i < p; i += 1 { for j := 0; j < m; j += 1 { best := 1000000000; for k := 0; k < m; k += 1 { candidate := cost[(i-1)*m+k] + int(values[2+p*m+k*m+j]); candidate += int(values[2+i*m+j]); if candidate < best do best = candidate }; cost[i*m+j] = best } }
	buffer: [2048]u8
	used := 0
	for i := 0; i < p; i += 1 { if i > 0 { buffer[used] = '\n'; used += 1 }; for j := 0; j < m; j += 1 { if j > 0 { buffer[used] = ','; used += 1 }; append_uint(&buffer[0],&used,cost[i*m+j]) } }
	if c.size_t(used) > capacity || (used > 0 && output == nil) do return -2
	for i := 0; i < used; i += 1 { output[i] = buffer[i] }
	return i64(used)
}
