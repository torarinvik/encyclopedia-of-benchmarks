module frobenius_number_apery

const max_parseable_length = usize(6)
const max_denomination = i64(16)
const distance_inf = i64(1_000_000)

fn gcd_i64(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn apery_frobenius(coins []i64, modulus int) i64 {
	mut distance := [16]i64{init: distance_inf}
	mut settled := [16]bool{}
	distance[0] = 0
	for _ in 0 .. modulus {
		mut source := -1
		mut best := distance_inf
		for residue in 0 .. modulus {
			if !settled[residue] && distance[residue] < best {
				source = residue
				best = distance[residue]
			}
		}
		if source < 0 { return -1 }
		settled[source] = true
		for coin in coins {
			target := (source + int(coin)) % modulus
			candidate := best + coin
			if candidate < distance[target] { distance[target] = candidate }
		}
	}
	mut maximum := i64(0)
	for residue in 0 .. modulus {
		if distance[residue] > maximum { maximum = distance[residue] }
	}
	return maximum - i64(modulus)
}

fn solve(values []i64) i64 {
	if values.len < 1 || values.len > max_parseable_length { return -1 }
	count_value := values[0]
	if count_value < 2 || count_value > 4 || values.len != usize(count_value + 1) { return -1 }
	coins := values[1..]
	mut common := i64(0)
	mut minimum := max_denomination + 1
	for i, coin in coins {
		if coin < 2 || coin > max_denomination { return -1 }
		for j in 0 .. i {
			if coin == coins[j] { return -1 }
		}
		common = gcd_i64(common, coin)
		if coin < minimum { minimum = coin }
	}
	if common != 1 { return -1 }
	return apery_frobenius(coins, int(minimum))
}

@[export: 'frobenius_number_apery']
pub fn frobenius_number_apery(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		mut values := [6]i64{}
		for index in 0 .. length {
			values[index] = input[index]
		}
		return solve(values[..length])
	}
}
