module strong_weak_balanced_prime_distribution

const max_limit = i64(100_000)

fn count(limit i64) i64 {
	mut prime := [200001]bool{}
	ceiling := 2 * limit
	for mut index := 0; index < prime.len; index++ { prime[index] = true }
	prime[0] = false
	prime[1] = false
	mut divisor := i64(2)
	for divisor * divisor <= ceiling; divisor++ {
		if !prime[divisor] { continue }
		mut multiple := divisor * divisor
		for multiple <= ceiling {
			prime[multiple] = false
			multiple += divisor
		}
	}

	mut strong := i64(0)
	mut weak := i64(0)
	mut balanced := i64(0)
	mut previous := i64(0)
	mut current := i64(0)
	mut candidate := i64(2)
	for candidate <= ceiling; candidate++ {
		if !prime[candidate] { continue }
		if previous != 0 && current >= 3 && current <= limit {
			twice := 2 * current
			neighbors := previous + candidate
			if twice > neighbors { strong++ }
			else if twice < neighbors { weak++ }
			else { balanced++ }
		}
		previous = current
		current = candidate
	}
	return strong * 10_000_000_000 + weak * 100_000 + balanced
}

@[export: 'strong_weak_balanced_prime_distribution']
pub fn strong_weak_balanced_prime_distribution(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 2 { return -1 }
		limit := input[0]
		if length != 1 || limit < 3 || limit > max_limit { return -1 }
		return count(limit)
	}
}
