package dividuus_number_predicate

import "core:c"

MAX_N :: i64(100000)
MAX_PARSEABLE_LENGTH :: 2

sum_digits :: proc "contextless" (value_arg: i64) -> i64 {
	value := value_arg
	total := i64(0)
	for value > 0 {
		total += value % 10
		value /= 10
	}
	return total
}

product_digits :: proc "contextless" (value_arg: i64) -> i64 {
	value := value_arg
	product := i64(1)
	for value > 0 {
		product *= value % 10
		value /= 10
	}
	return product
}

sum_root :: proc "contextless" (value_arg: i64) -> i64 {
	value := value_arg
	for value >= 10 do value = sum_digits(value)
	return value
}

product_root :: proc "contextless" (value_arg: i64) -> i64 {
	value := value_arg
	for value >= 10 do value = product_digits(value)
	return value
}

is_dividuus :: proc "contextless" (n: i64) -> bool {
	sum := sum_digits(n)
	product := product_digits(n)
	root := sum_root(n)
	mroot := product_root(n)
	if sum == 0 || product == 0 || root == 0 || mroot == 0 do return false
	return n % sum == 0 && n % product == 0 && n % root == 0 && n % mroot == 0
}

@(export)
dividuus_number_predicate :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	if length != 1 || input[0] < 1 || input[0] > MAX_N do return -1
	if is_dividuus(input[0]) do return 1
	return 0
}
