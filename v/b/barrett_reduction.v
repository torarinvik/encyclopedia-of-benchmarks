module barrett_reduction

const max_modulus = i64(65535)
const max_values = 12
const max_length = 15
const radix = i64(4294967296)

@[export: 'barrett_reduction']
pub fn barrett_reduction(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_length { return -1 }
		modulus := input[0]
		count_value := input[1]
		if modulus < 2 || modulus > max_modulus || count_value < 0 || count_value > max_values { return -1 }
		count := int(count_value)
		if length != usize(2+count) { return -1 }
		square_bound := modulus*modulus
		for i in 0 .. count {
			if input[2+i] < 0 || input[2+i] >= square_bound { return -1 }
		}
		reciprocal := radix/modulus
		mut checksum := i64(0)
		for i in 0 .. count {
			value := input[2+i]
			quotient := (value*reciprocal)/radix
			mut remainder := value-quotient*modulus
			if remainder >= modulus { remainder -= modulus }
			checksum += i64(i+1)*(remainder+1)
		}
		return checksum
	}
}
