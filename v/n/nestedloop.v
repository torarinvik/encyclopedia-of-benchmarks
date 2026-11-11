module nestedloop


@[export: 'nestedloop']
pub fn nestedloop(input i64) i64 {
	if input < 0 || input > 15 { return -1 }
	n := int(input)
	mut x := 0
	for a := 0; a < n; a++ {
		for b := 0; b < n; b++ {
			for c := 0; c < n; c++ {
				for d := 0; d < n; d++ {
					for e := 0; e < n; e++ {
						for f := 0; f < n; f++ {
							x++
						}
					}
				}
			}
		}
	}
	return i64(x)
}
