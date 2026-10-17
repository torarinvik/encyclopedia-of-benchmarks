// Count sol2's bounded, source-ordered digit-factorial chains.
module problem74_sol2

const max_chain_length = i64(60)
const max_number_limit = i64(1_000_000)
const path_capacity = 61
const digit_factorials = [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

fn digit_factorial_sum(value i64) i64 {
	mut remaining := value
	mut total := i64(0)
	for remaining > 0 {
		total += i64(digit_factorials[int(remaining % 10)])
		remaining /= 10
	}
	if value == 0 { return 1 }
	return total
}

fn cache_contains(value i64, number_limit i64, cache []u32) bool {
	return value >= 1 && value < number_limit && cache[int(value)] != 0
}

fn path_contains(path []i64, value i64) bool {
	for term in path {
		if term == value { return true }
	}
	return false
}

@[export: 'problem74_sol2']
pub fn problem74_sol2(chain_length i64, number_limit i64) i64 {
	if chain_length < 1 || chain_length > max_chain_length || number_limit < 1 || number_limit > max_number_limit {
		return -1
	}
	if number_limit == 1 { return 0 }

	mut cache := []u32{len: int(number_limit)}
	mut chains_counter := i64(0)
	for start := i64(1); start < number_limit; start++ {
		mut path := [path_capacity]i64{}
		mut path_length := 0
		mut chain_set_length := i64(0)
		mut chain_element := start
		for !cache_contains(chain_element, number_limit, cache) &&
			!path_contains(path[..path_length], chain_element) && chain_set_length <= chain_length {
			path[path_length] = chain_element
			path_length++
			chain_set_length++
			chain_element = digit_factorial_sum(chain_element)
		}
		if cache_contains(chain_element, number_limit, cache) {
			chain_set_length += i64(cache[int(chain_element)])
		}
		cache[int(start)] = u32(chain_set_length)
		if chain_set_length == chain_length { chains_counter++ }
	}
	return chains_counter
}
