package frobenius_number_apery

import "core:c"

MAX_PARSEABLE_LENGTH :: 6
MAX_DENOMINATIONS :: i64(4)
MAX_DENOMINATION :: i64(16)
DISTANCE_INF :: i64(1_000_000)

gcd_i64 :: proc(left_value, right_value: i64) -> i64 {
	left := left_value
	right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

apery_frobenius :: proc(coins: []i64, count, modulus: int) -> i64 {
	distance: [16]i64
	settled: [16]bool
	for residue := 0; residue < modulus; residue += 1 {
		distance[residue] = DISTANCE_INF
	}
	distance[0] = 0
	for step := 0; step < modulus; step += 1 {
		source := -1
		best := DISTANCE_INF
		for residue := 0; residue < modulus; residue += 1 {
			if !settled[residue] && distance[residue] < best {
				source = residue
				best = distance[residue]
			}
		}
		if source < 0 do return -1
		settled[source] = true
		for index := 0; index < count; index += 1 {
			coin := coins[index]
			target := (source + int(coin)) % modulus
			candidate := best + coin
			if candidate < distance[target] do distance[target] = candidate
		}
	}
	maximum: i64 = 0
	for residue := 0; residue < modulus; residue += 1 {
		if distance[residue] > maximum do maximum = distance[residue]
	}
	return maximum - i64(modulus)
}

@(export)
frobenius_number_apery :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	count := input[0]
	if count < 2 || count > MAX_DENOMINATIONS || length != c.size_t(count + 1) do return -1
	common: i64 = 0
	minimum := MAX_DENOMINATION + 1
	coins: [4]i64
	for index: i64 = 0; index < count; index += 1 {
		coin := input[index + 1]
		if coin < 2 || coin > MAX_DENOMINATION do return -1
		for previous: i64 = 0; previous < index; previous += 1 {
			if coin == input[previous + 1] do return -1
		}
		common = gcd_i64(common, coin)
		if coin < minimum do minimum = coin
		coins[index] = coin
	}
	if common != 1 do return -1
	return apery_frobenius(coins[:int(count)], int(count), int(minimum))
}
