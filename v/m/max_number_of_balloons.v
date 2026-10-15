module main

@[export: 'max_number_of_balloons']
pub fn max_number_of_balloons(text &i64, length usize) i64 {
	unsafe {
		if length > 256 {
			return -1
		}
		mut b := i64(0)
		mut a := i64(0)
		mut l := i64(0)
		mut o := i64(0)
		mut n := i64(0)
		for index in 0 .. int(length) {
			value := text[index]
			if value < 97 || value > 122 {
				return -1
			}
			if value == 98 {
				b += 1
			} else if value == 97 {
				a += 1
			} else if value == 108 {
				l += 1
			} else if value == 111 {
				o += 1
			} else if value == 110 {
				n += 1
			}
		}
		l /= 2
		o /= 2
		mut minimum := b
		if a < minimum { minimum = a }
		if l < minimum { minimum = l }
		if o < minimum { minimum = o }
		if n < minimum { minimum = n }
		return minimum
	}
}
