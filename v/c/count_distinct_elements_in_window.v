module count_distinct_elements_in_window

const max_n = 256
const hash_capacity = 512

fn hash_slot(value i32) int {
	bits := u32(value)
	mixed := u64(bits) * u64(2654435761)
	return int(u32(mixed) >> 23)
}

fn find_slot(keys &i32, occupied &bool, value i32) int {
	mut slot := hash_slot(value)
	unsafe {
		for _ in 0 .. hash_capacity {
			if !occupied[slot] || keys[slot] == value { return slot }
			slot = (slot + 1) % hash_capacity
		}
	}
	return 0
}

fn put_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}

@[export: 'count_distinct_elements_in_window']
pub fn count_distinct_elements_in_window(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if input[1] < 1 || input[1] > i64(n) || length != usize(n + 2) { return -1 }
		k := int(input[1])
		out_n := n - k + 1
		for i in 0 .. n { if input[i + 2] < -2147483648 || input[i + 2] > 2147483647 { return -1 } }
		if output == nil || capacity < usize(out_n * 8) { return -2 }

		mut keys := [hash_capacity]i32{}
		mut counts := [hash_capacity]i32{}
		mut occupied := [hash_capacity]bool{}
		mut distinct := i64(0)
		for i in 0 .. k {
			value := i32(input[i + 2])
			slot := find_slot(&keys[0], &occupied[0], value)
			if !occupied[slot] { keys[slot] = value; occupied[slot] = true; counts[slot] = 0 }
			if counts[slot] == 0 { distinct++ }
			counts[slot]++
		}
		put_i64_le(output, 0, distinct)
		for i in k .. n {
			incoming := i32(input[i + 2])
			mut slot := find_slot(&keys[0], &occupied[0], incoming)
			if !occupied[slot] { keys[slot] = incoming; occupied[slot] = true; counts[slot] = 0 }
			if counts[slot] == 0 { distinct++ }
			counts[slot]++
			outgoing := i32(input[i - k + 2])
			slot = find_slot(&keys[0], &occupied[0], outgoing)
			counts[slot]--
			if counts[slot] == 0 { distinct-- }
			put_i64_le(output, (i - k + 1) * 8, distinct)
		}
		return i64(out_n * 8)
	}
}
