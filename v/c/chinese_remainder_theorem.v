module chinese_remainder_theorem

const max_inputs = 8
const max_modulus = i64(1000)

fn modular_inverse(value i64, modulus i64) i64 {
	mut old_remainder := value % modulus
	mut remainder := modulus
	mut old_coefficient := i64(1)
	mut coefficient := i64(0)
	for remainder != 0 {
		quotient := old_remainder / remainder
		next_remainder := old_remainder - quotient * remainder
		old_remainder = remainder
		remainder = next_remainder
		next_coefficient := old_coefficient - quotient * coefficient
		old_coefficient = coefficient
		coefficient = next_coefficient
	}
	if old_remainder != 1 { return -1 }
	old_coefficient %= modulus
	if old_coefficient < 0 { old_coefficient += modulus }
	return old_coefficient
}

@[export: 'chinese_remainder_theorem']
pub fn chinese_remainder_theorem(values &i64, length usize) i64 {
	if length < 2 || length > max_inputs || length % 2 != 0 { return -1 }
	mut result := i64(0)
	mut product := i64(1)
	mut index := usize(0)
	for index < length {
		residue := unsafe { values[index] }
		modulus := unsafe { values[index + 1] }
		if modulus < 2 || modulus > max_modulus || residue < 0 || residue >= modulus { return -1 }
		inverse := modular_inverse(product % modulus, modulus)
		if inverse < 0 { return -1 }
		mut difference := residue - result % modulus
		if difference < 0 { difference += modulus }
		factor := difference * inverse % modulus
		result += product * factor
		product *= modulus
		index += 2
	}
	return result
}
