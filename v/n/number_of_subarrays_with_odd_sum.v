module number_of_subarrays_with_odd_sum

// Count subarrays with an odd sum, modulo 1,000,000,007.
@[export: 'number_of_subarrays_with_odd_sum']
pub fn number_of_subarrays_with_odd_sum(values &i64, length usize) i64 {
	if length > 100_000 { return -1 }
	unsafe {
		mut even_prefixes := i64(1)
		mut odd_prefixes := i64(0)
		mut result := i64(0)
		mut parity := i64(0)
		for index in 0 .. length {
			value := values[index]
			if value < -2_147_483_648 || value > 2_147_483_647 { return -1 }
			if value % 2 != 0 { parity = 1 - parity }
			if parity == 0 {
				result = (result + odd_prefixes) % 1_000_000_007
				even_prefixes++
			} else {
				result = (result + even_prefixes) % 1_000_000_007
				odd_prefixes++
			}
		}
		return result
	}
}
