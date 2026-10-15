module is_polish_national_id

@[export: 'is_polish_national_id']
pub fn is_polish_national_id(input &i64, length usize) i64 {
	if length != 11 { return -1 }
	mut number := i64(0)
	for index in 0 .. 11 {
		value := unsafe { input[index] }
		if value < 48 || value > 57 { return -1 }
		number = number * 10 + value - 48
	}
	if number < 10100000 || number > 99923199999 { return 0 }
	month := (unsafe { input[2] } - 48) * 10 + unsafe { input[3] } - 48
	valid_month := (month >= 1 && month <= 12) || (month >= 21 && month <= 32) ||
		(month >= 41 && month <= 52) || (month >= 61 && month <= 72) || (month >= 81 && month <= 92)
	if !valid_month { return 0 }
	day := (unsafe { input[4] } - 48) * 10 + unsafe { input[5] } - 48
	if day < 1 || day > 31 { return 0 }
	mut subtotal := i64(0)
	for index in 0 .. 10 {
		value := unsafe { input[index] }
		mut weight := i64(1)
		if index % 4 == 1 { weight = 3 }
		if index % 4 == 2 { weight = 7 }
		if index % 4 == 3 { weight = 9 }
		subtotal += ((value - 48) * weight) % 10
	}
	checksum := 10 - subtotal % 10
	if checksum == number % 10 { return 1 }
	return 0
}
