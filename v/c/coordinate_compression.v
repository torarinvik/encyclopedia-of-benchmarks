module coordinate_compression

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'coordinate_compression']
pub fn coordinate_compression(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		n64 := input[0]
		if n64 < 0 || n64 > 128 || length != usize(n64) + 1 { return -1 }
		n := int(n64)
		mut sorted := []i64{len: n, init: 0}
		for i in 0 .. n {
			value := input[i+1]
			if value < -2147483648 || value > 2147483647 { return -1 }
			sorted[i] = value
		}
		if capacity < n*8 || (n > 0 && unsafe { output == nil }) { return -2 }
		sorted.sort()
		mut ranks := []i64{len: n, init: 0}
		mut rank := i64(-1)
		for i in 0 .. n {
			if i == 0 || sorted[i] != sorted[i-1] { rank++ }
			ranks[i] = rank
		}
		for i in 0 .. n {
			mut low := 0
			mut high := n
			for low < high {
				middle := low + (high-low)/2
				if sorted[middle] < input[i+1] { low = middle + 1 } else { high = middle }
			}
			put_i64_le(mut output, i*8, ranks[low])
		}
		return i64(n*8)
	}
}
