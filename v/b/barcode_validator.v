module barcode_validator

fn get_check_digit(input i64) i64 {
	mut barcode := input / 10
	mut checker := false
	mut total := i64(0)
	for barcode != 0 {
		mut multiplier := i64(3)
		if checker { multiplier = 1 }
		total += multiplier * (barcode % 10)
		barcode /= 10
		checker = !checker
	}
	return (10 - total % 10) % 10
}

fn decimal_length(input i64) int {
	mut value := input
	mut length := 1
	for value >= 10 {
		value /= 10
		length++
	}
	return length
}

@[export: 'barcode_validator']
pub fn barcode_validator(values &i64, length usize) i64 {
	if length != 2 { return -1 }
	operation := unsafe { values[0] }
	barcode := unsafe { values[1] }
	if operation < 0 || operation > 1 || barcode < 0 { return -1 }
	if operation == 0 { return get_check_digit(barcode) }
	if decimal_length(barcode) == 13 && get_check_digit(barcode) == barcode % 10 { return 1 }
	return 0
}
