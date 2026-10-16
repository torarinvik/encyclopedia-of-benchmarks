package problem125

MAX_LIMIT :: 100_000_000
HASH_CAPACITY :: 32768
HASH_MASK :: HASH_CAPACITY - 1

is_palindrome :: proc(value: i64) -> bool {
	if value % 10 == 0 do return false
	original := value
	remaining := value
	reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
	}
	return original == reversed
}

insert_unique :: proc(seen: [^]i64, value: i64) -> bool {
	slot := int(((u64(value) * u64(2_654_435_761)) >> 17) & u64(HASH_MASK))
	for seen[slot] != 0 && seen[slot] != value { slot = (slot + 1) & HASH_MASK }
	if seen[slot] == value do return false
	seen[slot] = value
	return true
}

@(export)
problem125 :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > MAX_LIMIT do return -1
	seen: [HASH_CAPACITY]i64 = {}
	total := i64(0)
	first := i64(1)
	for {
		last := first + 1
		sum := first * first + last * last
		if sum >= limit do break
		for sum < limit {
			if is_palindrome(sum) && insert_unique(&seen[0], sum) { total += sum }
			last += 1
			sum += last * last
		}
		first += 1
	}
	return total
}
