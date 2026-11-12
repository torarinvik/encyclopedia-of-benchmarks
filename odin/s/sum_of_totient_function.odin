package sum_of_totient_function

Max_N :: i64(1_000_000_000)
Base_Limit :: 100_000
Max_Cache :: 10_002
Modulus :: i64(998_244_353)

triangular_mod :: proc "contextless" (n: i64) -> i64 {
	left, right := n, n + 1
	if left % 2 == 0 { left /= 2 } else { right /= 2 }
	return (left % Modulus) * (right % Modulus) % Modulus
}

summatory_phi :: proc "contextless" (value, total_n: i64, prefix, memo: ^i64, visited: ^bool) -> i64 {
	if value <= i64(Base_Limit) do return prefix[int(value)]
	cache_index := int(total_n / value)
	if visited[cache_index] do return memo[cache_index]
	answer := triangular_mod(value)
	left := i64(2)
	for left <= value {
		quotient := value / left
		right := value / quotient
		block_size := right - left + 1
		sub_sum := summatory_phi(quotient, total_n, prefix, memo, visited)
		contribution := (block_size % Modulus) * sub_sum % Modulus
		answer = (answer - contribution + Modulus) % Modulus
		left = right + 1
	}
	visited[cache_index] = true
	memo[cache_index] = answer
	return answer
}

@(export)
sum_of_totient_function :: proc "c" (n: i64) -> i64 {
	if n < 1 || n > Max_N do return -1
	prefix: [Base_Limit + 1]i64 = {}
	for value := 0; value <= Base_Limit; value += 1 { prefix[value] = i64(value) }
	sieve_limit := min(int(n), Base_Limit)
	for prime := 2; prime <= sieve_limit; prime += 1 {
		if prefix[prime] != i64(prime) do continue
		for multiple := prime; multiple <= sieve_limit; multiple += prime {
			prefix[multiple] -= prefix[multiple] / i64(prime)
		}
	}
	running := i64(0)
	for value := 1; value <= sieve_limit; value += 1 {
		running = (running + prefix[value]) % Modulus
		prefix[value] = running
	}
	if n <= i64(Base_Limit) do return prefix[int(n)]

	memo: [Max_Cache]i64 = {}
	visited: [Max_Cache]bool = {}
	return summatory_phi(n, n, &prefix[0], &memo[0], &visited[0])
}
