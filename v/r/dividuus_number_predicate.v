module main

const max_n = i64(100000)
const max_parseable_length = usize(2)

fn digit_sum(value_arg i64) i64 {
	mut value := value_arg
	mut total := i64(0)
	for value > 0 {
		total += value % 10
		value /= 10
	}
	return total
}

fn digit_product(value_arg i64) i64 {
	mut value := value_arg
	mut product := i64(1)
	for value > 0 {
		product *= value % 10
		value /= 10
	}
	return product
}

fn digital_root(value_arg i64) i64 {
	mut value := value_arg
	for value >= 10 { value = digit_sum(value) }
	return value
}

fn multiplicative_root(value_arg i64) i64 {
	mut value := value_arg
	for value >= 10 { value = digit_product(value) }
	return value
}

fn is_dividuus(n i64) bool {
	sum := digit_sum(n)
	product := digit_product(n)
	root := digital_root(n)
	mroot := multiplicative_root(n)
	if sum == 0 || product == 0 || root == 0 || mroot == 0 { return false }
	return n % sum == 0 && n % product == 0 && n % root == 0 && n % mroot == 0
}

@[export: 'dividuus_number_predicate']
pub fn dividuus_number_predicate(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		if length != 1 { return -1 }
		n := input[0]
		if n < 1 || n > max_n { return -1 }
		if is_dividuus(n) { return 1 }
		return 0
	}
}
