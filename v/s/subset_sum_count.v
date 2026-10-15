module subset_sum_count

// Count indexed signed subsets that reach the requested sum.
@[export: 'subset_sum_count']
pub fn subset_sum_count(input &i64, length usize) i64 {
	if length == 0 || length > 25 { return -1 }
	target := unsafe { input[0] }
	if target < -6144 || target > 6144 { return -1 }
	for index in 1 .. length {
		value := unsafe { input[index] }
		if value < -256 || value > 256 { return -1 }
	}
	mut ways := [12289]i64{}
	ways[6144] = 1
	mut low := i64(0)
	mut high := i64(0)
	for index in 1 .. length {
		value := unsafe { input[index] }
		if value > 0 {
			mut sum := high
			for sum >= low {
				ways[int(sum + value + 6144)] += ways[int(sum + 6144)]
				sum--
			}
			high += value
		} else if value < 0 {
			mut sum := low
			for sum <= high {
				ways[int(sum + value + 6144)] += ways[int(sum + 6144)]
				sum++
			}
			low += value
		} else {
			mut sum := low
			for sum <= high {
				ways[int(sum + 6144)] *= 2
				sum++
			}
		}
	}
	return ways[int(target + 6144)]
}
