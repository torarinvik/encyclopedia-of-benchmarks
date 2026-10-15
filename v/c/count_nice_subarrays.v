module count_nice_subarrays

const max_length = 4096

@[export: 'count_nice_subarrays']
pub fn count_nice_subarrays(values &i64, length usize) i64 {
	if length < 2 { return -1 }
	n_value := unsafe { values[0] }
	k_value := unsafe { values[1] }
	if n_value < 0 || n_value > max_length || k_value < 1 || k_value > max_length { return -1 }
	n := int(n_value)
	k := int(k_value)
	if length != usize(n + 2) { return -1 }
	for i in 0 .. n {
		value := unsafe { values[i + 2] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	mut memo := []i32{len: n}
	mut left := 0
	mut odd_count := 0
	mut result := i64(0)
	for right in 0 .. n {
		value := unsafe { values[right + 2] }
		if (i32(value) & 1) == 1 { odd_count++ }
		if odd_count > k {
			left += int(memo[left])
			odd_count--
		}
		if odd_count == k {
			if memo[left] == 0 {
				mut even_count := 0
				mut temp := left
				for {
					even_value := unsafe { values[temp + 2] }
					if (i32(even_value) & 1) != 0 { break }
					even_count++
					temp++
				}
				memo[left] = i32(even_count + 1)
			}
			result += i64(memo[left])
		}
	}
	return result
}
