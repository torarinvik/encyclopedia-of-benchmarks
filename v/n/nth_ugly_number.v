module nth_ugly_number

// Return the zero-based 5-smooth number at index n.
@[export: 'nth_ugly_number']
pub fn nth_ugly_number(n i64) i64 {
	if n < 0 || n > 12690 { return -1 }
	mut values := [12691]i64{}
	values[0] = 1
	mut i2 := 0
	mut i3 := 0
	mut i5 := 0
	for index := 1; index <= int(n); index++ {
		c2 := 2 * values[i2]
		c3 := 3 * values[i3]
		c5 := 5 * values[i5]
		mut next := c2
		if c3 < next { next = c3 }
		if c5 < next { next = c5 }
		values[index] = next
		if c2 == next { i2++ }
		if c3 == next { i3++ }
		if c5 == next { i5++ }
	}
	return values[int(n)]
}
