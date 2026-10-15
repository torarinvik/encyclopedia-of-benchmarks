module is_spain_national_id

const check_letters = 'TRWAGMYFPDXBNJZSQVHLCKE'

@[export: 'is_spain_national_id']
pub fn is_spain_national_id(input &i64, length usize) i64 {
	if length != 9 && length != 10 { return -1 }
	for index in 0 .. length {
		value := unsafe { input[index] }
		if value < 0 || value > 127 { return -1 }
	}
	if length == 10 && unsafe { input[8] } != 45 { return -1 }
	mut number := i64(0)
	for index in 0 .. 8 {
		value := unsafe { input[index] }
		if value < 48 || value > 57 { return -1 }
		number = number * 10 + value - 48
	}
	mut letter := unsafe { input[length - 1] }
	if letter >= 97 && letter <= 122 { letter -= 32 }
	if letter < 65 || letter > 90 { return -1 }
	return if letter == i64(check_letters[int(number % 23)]) { 1 } else { 0 }
}
