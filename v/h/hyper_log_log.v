import math

const max_count = 1024
const register_count = 65536

@[export: 'hyper_log_log']
pub fn hyper_log_log(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_count + 1 { return -1 }
	count64 := unsafe { input[0] }
	if count64 < 1 || count64 > max_count || length != usize(count64 + 1) { return -1 }
	count := int(count64)
	for i in 0 .. count {
		value := unsafe { input[1 + i] }
		if value < 1 || value > 65535 { return -1 }
	}

	mut registers := [register_count]u8{}
	mut seen := [register_count]u8{}
	mut touched := [max_count]u16{}
	mut touched_count := 0
	for i in 0 .. count {
		value := u32(unsafe { input[1 + i] })
		mut bits := value
		mut rank := u8(0)
		for (bits & 1) == 0 { rank++; bits >>= 1 }
		index := int(value)
		if seen[index] == 0 { seen[index] = 1; touched[touched_count] = u16(value); touched_count++ }
		if rank > registers[index] { registers[index] = rank }
	}

	mut z := 0.0
	for i in 0 .. touched_count { z += 1.0 / f64(u32(1) << registers[int(touched[i])]) }
	k := f64(touched_count)
	return i64(math.ceil(0.673 * k * (k / z)))
}
