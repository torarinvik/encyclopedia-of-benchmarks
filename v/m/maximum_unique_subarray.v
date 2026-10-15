module maximum_unique_subarray

// Maximize the sum of a contiguous window with distinct values.
@[export: 'maximum_unique_subarray']
pub fn maximum_unique_subarray(values &i64, length usize) i64 {
	if length > 256 { return -1 }
	if length == 0 { return 0 }
	unsafe {
		mut keys := [512]i64{}
		mut last_seen := [512]usize{}
		mut occupied := [512]bool{}
		mut left := usize(0)
		mut window_sum := i64(0)
		mut best := i64(0)
		for index in 0 .. length {
			value := values[index]
			if value < 1 || value > 10_000 { return -1 }
			slot := int(value % 512)
			for occupied[slot] && keys[slot] != value { slot = (slot + 1) % 512 }
			previous := last_seen[slot]
			for left < previous {
				window_sum -= values[left]
				left++
			}
			window_sum += value
			keys[slot] = value
			last_seen[slot] = index + 1
			occupied[slot] = true
			if window_sum > best { best = window_sum }
		}
		return best
	}
}
