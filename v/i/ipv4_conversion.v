module ipv4_conversion

const invalid_result = i64(-9223372036854775807 - 1)

@[export: 'ipv4_conversion']
pub fn ipv4_conversion(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 4 { return invalid_result }
	unsafe {
		mut address := i64(0)
		for index in 0 .. 4 {
			octet := input[index]
			if octet < 0 || octet > 255 { return invalid_result }
			address = address * 256 + octet
		}
		return address
	}
}
