module problem125

const max_limit = i64(100000000)
const hash_capacity = 32768
const hash_mask = hash_capacity - 1

fn is_palindrome(value i64) bool {
	if value % 10 == 0 { return false }
	original := value
	mut remaining := value
	mut reversed := i64(0)
	for remaining > 0 {
		reversed = reversed * 10 + remaining % 10
		remaining /= 10
	}
	return original == reversed
}

@[export: 'problem125']
pub fn problem125(limit i64) i64 {
	if limit < 0 || limit > max_limit { return -1 }
	mut seen := [hash_capacity]i64{init: 0}
	mut total := i64(0)
	mut first := i64(1)
	for {
		mut last := first + 1
		mut sum := first * first + last * last
		if sum >= limit { break }
		for sum < limit {
			if is_palindrome(sum) {
				mut slot := int(((u64(sum) * u64(2654435761)) >> 17) & u64(hash_mask))
				for seen[slot] != 0 && seen[slot] != sum { slot = (slot + 1) & hash_mask }
				if seen[slot] == 0 { seen[slot] = sum; total += sum }
			}
			last++
			sum += last * last
		}
		first++
	}
	return total
}
