module cube_root_proper_divisor_product

const max_input_length = 2
const max_value = 600_000
const max_k = i64(50_000)

fn build_prime_prefix(mut prefix []u32) {
	prefix[0] = 0
	prefix[1] = 0
	for value in 2 .. max_value + 1 { prefix[value] = 1 }
	mut prime := 2
	for prime <= max_value / prime {
		if prefix[prime] != 0 {
			mut multiple := prime * prime
			for multiple <= max_value {
				prefix[multiple] = 0
				multiple += prime
			}
		}
		prime++
	}
	for value in 1 .. max_value + 1 { prefix[value] += prefix[value - 1] }
}

fn is_prime(value int, prefix []u32) bool {
	return value >= 2 && prefix[value] - prefix[value - 1] == 1
}

fn count_tau_eight(limit int, prefix []u32) i64 {
	mut count := i64(0)
	mut prime := u64(2)
	for {
		mut power := u64(1)
		for _ in 0 .. 7 {
			if power > u64(limit) / prime {
				power = u64(limit) + 1
				break
			}
			power *= prime
		}
		if power > u64(limit) { break }
		if is_prime(int(prime), prefix) { count++ }
		prime++
	}
	prime = 2
	for {
		cube := prime * prime * prime
		if cube > u64(limit) { break }
		if is_prime(int(prime), prefix) {
			q_max := int(u64(limit) / cube)
			count += i64(prefix[q_max])
			if prime <= u64(q_max) { count-- }
		}
		prime++
	}
	prime = 2
	for prime * prime * prime < u64(limit) {
		if is_prime(int(prime), prefix) {
			mut other := prime + 1
			for {
				if prime > u64(limit) / other { break }
				product := prime * other
				last_prime := int(u64(limit) / product)
				if u64(last_prime) <= other { break }
				if is_prime(int(other), prefix) {
					count += i64(prefix[last_prime] - prefix[int(other)])
				}
				other++
			}
		}
		prime++
	}
	return count
}

fn sequence_term(k i64) i64 {
	if k == 1 { return 1 }
	mut prefix := [max_value + 1]u32{init: 0}
	build_prime_prefix(mut prefix[..])
	target := k - 1
	if count_tau_eight(max_value, prefix[..]) < target { return -1 }
	mut low := 1
	mut high := max_value
	for low < high {
		middle := low + (high - low) / 2
		if count_tau_eight(middle, prefix[..]) >= target { high = middle } else { low = middle + 1 }
	}
	return i64(low)
}

@[export: 'cube_root_proper_divisor_product']
pub fn cube_root_proper_divisor_product(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		if length != 1 || input[0] < 1 || input[0] > max_k { return -1 }
		return sequence_term(input[0])
	}
}
