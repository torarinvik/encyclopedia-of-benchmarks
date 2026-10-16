module parse_integer

const invalid_result = i64(-9223372036854775807 - 1)
const uint32_modulus = i64(4294967296)

@[export: 'parse_integer']
pub fn parse_integer(bytes &i64, length usize) i64 {
	if length == 0 || length > 64 { return invalid_result }
	unsafe {
		for index in 0 .. int(length) {
			if bytes[index] < 0 || bytes[index] > 127 { return invalid_result }
		}
		negative := bytes[0] == 45
		mut index := if bytes[0] == 45 || bytes[0] == 43 { 1 } else { 0 }
		mut number := i64(0)
		for index < int(length) {
			byte := bytes[index]
			if byte < 48 || byte > 57 { return invalid_result }
			number = (number * 10 + byte - 48) % uint32_modulus
			index++
		}
		if negative && number != 0 { number = uint32_modulus - number }
		if number >= 2_147_483_648 { return number - uint32_modulus }
		return number
	}
}
