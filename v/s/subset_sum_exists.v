module subset_sum_exists

// Decide whether a signed integer subset reaches the requested sum.
@[export: 'subset_sum_exists']
pub fn subset_sum_exists(input &i64, length usize) i64 {
	if length == 0 || length > 25 { return -1 }
	target := unsafe { input[0] }
	if target < -6144 || target > 6144 { return -1 }
	for index in 1 .. length {
		value := unsafe { input[index] }
		if value < -256 || value > 256 { return -1 }
	}
	mut reachable := [12289]bool{init: false}
	reachable[6144] = true
	mut low := i64(0)
	mut high := i64(0)
	for index in 1 .. length {
		value := unsafe { input[index] }
		if value > 0 {
			mut sum := high
			for sum >= low {
				if reachable[int(sum + 6144)] { reachable[int(sum + value + 6144)] = true }
				sum--
			}
			high += value
		} else if value < 0 {
			mut sum := low
			for sum <= high {
				if reachable[int(sum + 6144)] { reachable[int(sum + value + 6144)] = true }
				sum++
			}
			low += value
		}
	}
	return if reachable[int(target + 6144)] { 1 } else { 0 }
}
