module sum_of_totient_function

const max_n = i64(1_000_000_000)
const base_limit = 100_000
const max_cache = 10_002
const modulus = i64(998_244_353)

fn triangular_mod(n i64) i64 {
	mut left := n
	mut right := n + 1
	if left % 2 == 0 { left /= 2 } else { right /= 2 }
	return left % modulus * (right % modulus) % modulus
}

fn summatory_phi(value i64, total_n i64, prefix []i64, mut memo []i64, mut visited []bool) i64 {
	if value <= i64(base_limit) { return prefix[int(value)] }
	cache_index := int(total_n / value)
	if visited[cache_index] { return memo[cache_index] }
	mut answer := triangular_mod(value)
	mut left := i64(2)
	for left <= value {
		quotient := value / left
		right := value / quotient
		block_size := right - left + 1
		sub_sum := summatory_phi(quotient, total_n, prefix, mut memo, mut visited)
		contribution := block_size % modulus * sub_sum % modulus
		answer = (answer - contribution + modulus) % modulus
		left = right + 1
	}
	visited[cache_index] = true
	memo[cache_index] = answer
	return answer
}

@[export: 'sum_of_totient_function']
pub fn sum_of_totient_function(n i64) i64 {
	if n < 1 || n > max_n { return -1 }
	mut prefix := []i64{len: base_limit + 1, init: 0}
	for value in 0 .. base_limit + 1 { prefix[value] = i64(value) }
	sieve_limit := min(int(n), base_limit)
	for prime in 2 .. sieve_limit + 1 {
		if prefix[prime] != i64(prime) { continue }
		mut multiple := prime
		for multiple <= sieve_limit {
			prefix[multiple] -= prefix[multiple] / i64(prime)
			multiple += prime
		}
	}
	mut running := i64(0)
	for value in 1 .. sieve_limit + 1 {
		running = (running + prefix[value]) % modulus
		prefix[value] = running
	}
	if n <= i64(base_limit) { return prefix[int(n)] }
	mut memo := []i64{len: max_cache, init: 0}
	mut visited := []bool{len: max_cache, init: false}
	return summatory_phi(n, n, prefix, mut memo, mut visited)
}
