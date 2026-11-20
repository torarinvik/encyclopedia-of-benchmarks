module yellowstone_permutation_prefix

const max_n = i64(64)
const min_cap = i64(3)
const max_cap = i64(256)
const max_parseable_length = 3

fn ypp_gcd(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn ypp_construct(requested i64, candidate_cap i64) i64 {
	mut terms := [64]i64{}
	mut used := [257]bool{}
	terms[0] = 1
	terms[1] = 2
	terms[2] = 3
	if requested <= 3 { return terms[int(requested - 1)] }
	used[1] = true
	used[2] = true
	used[3] = true

	mut term_count := 3
	for term_count < int(requested) {
		two_back := terms[term_count - 2]
		previous := terms[term_count - 1]
		mut candidate := i64(1)
		for candidate <= candidate_cap {
			if !used[int(candidate)] && ypp_gcd(candidate, two_back) > 1 && ypp_gcd(candidate, previous) == 1 { break }
			candidate++
		}
		if candidate > candidate_cap { return -1 }
		terms[term_count] = candidate
		used[int(candidate)] = true
		term_count++
	}
	return terms[int(requested - 1)]
}

@[export: 'yellowstone_permutation_prefix']
pub fn yellowstone_permutation_prefix(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 2 { return -1 }
		requested := input[0]
		candidate_cap := input[1]
		if requested < 1 || requested > max_n || candidate_cap < min_cap || candidate_cap > max_cap { return -1 }
		return ypp_construct(requested, candidate_cap)
	}
}
