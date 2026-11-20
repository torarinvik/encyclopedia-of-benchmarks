module shewchuk_expansion_sum

const max_terms = 16
const max_length = 34
const max_mantissa = i64(16777216)
const output_scale = f64(1073741824.0)

struct SumPair {
	high f64
	low f64
}

fn two_sum(a f64, b f64) SumPair {
	rounded := a+b
	b_virtual := rounded-a
	a_virtual := rounded-b_virtual
	b_roundoff := b-b_virtual
	a_roundoff := a-a_virtual
	return SumPair{high: rounded, low: a_roundoff+b_roundoff}
}

fn grow_expansion(expansion []f64, value f64, mut grown []f64) int {
	mut q := value
	mut grown_count := 0
	for component in expansion {
		pair := two_sum(q,component)
		if pair.low != 0.0 {
			grown[grown_count] = pair.low
			grown_count++
		}
		q = pair.high
	}
	if q != 0.0 || grown_count == 0 {
		grown[grown_count] = q
		grown_count++
	}
	return grown_count
}

@[export: 'shewchuk_expansion_sum']
pub fn shewchuk_expansion_sum(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_length { return -1 }
		if input[0] < 0 || input[0] > max_terms { return -1 }
		n := int(input[0])
		if length != usize(1+2*n) { return -1 }
		mut expansion := [max_terms+1]f64{}
		mut grown := [max_terms+1]f64{}
		mut expansion_count := 0
		for i in 0 .. n {
			mantissa := input[1+2*i]
			exponent := input[2+2*i]
			if mantissa < -max_mantissa || mantissa > max_mantissa || exponent < -30 || exponent > 0 { return -1 }
			mut value := f64(mantissa)
			mut shift := i64(0)
			for shift > exponent {
				value *= 0.5
				shift--
			}
			if value != 0.0 {
				grown_count := grow_expansion(expansion[..expansion_count],value,mut grown[..])
				for j in 0 .. grown_count { expansion[j] = grown[j] }
				expansion_count = grown_count
			}
		}
		mut result := (i64(1) << 58)+1
		for i in 0 .. expansion_count { result += i64(expansion[i]*output_scale) }
		return result
	}
}
