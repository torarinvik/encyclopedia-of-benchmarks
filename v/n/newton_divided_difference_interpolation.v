module newton_divided_difference_interpolation

const modulus = i64(998244353)
const max_nodes = 12
const max_length = 27

fn mod_pow(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'newton_divided_difference_interpolation']
pub fn newton_divided_difference_interpolation(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_length { return -1 }
		if input[0] < 1 || input[0] > max_nodes { return -1 }
		count := int(input[0])
		if length != usize(2+2*count) { return -1 }
		mut nodes := [max_nodes]i64{}
		mut differences := [max_nodes]i64{}
		for i in 0 .. count {
			nodes[i] = input[1+i]
			differences[i] = input[1+count+i]
			if nodes[i] < 0 || nodes[i] >= modulus || differences[i] < 0 || differences[i] >= modulus { return -1 }
			for j in 0 .. i {
				if nodes[i] == nodes[j] { return -1 }
			}
		}
		query := input[length-1]
		if query < 0 || query >= modulus { return -1 }
		for order in 1 .. count {
			for offset in 0 .. count-order {
				i := count-1-offset
				numerator := differences[i]-differences[i-1]
				if numerator < 0 { numerator += modulus }
				denominator := nodes[i]-nodes[i-order]
				if denominator < 0 { denominator += modulus }
				differences[i] = numerator*mod_pow(denominator,modulus-2)%modulus
			}
		}
		mut result := differences[count-1]
		for offset in 0 .. count-1 {
			i := count-2-offset
			mut factor := query-nodes[i]
			if factor < 0 { factor += modulus }
			result = (result*factor+differences[i])%modulus
		}
		return result
	}
}
