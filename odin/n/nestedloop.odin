package nestedloop

MAX_N :: 15

@(export)
nestedloop :: proc "c" (input: i64) -> i64 {
	if input < 0 || input > MAX_N do return -1
	n := int(input)
	x := 0
	for a := 0; a < n; a += 1 {
		for b := 0; b < n; b += 1 {
			for c := 0; c < n; c += 1 {
				for d := 0; d < n; d += 1 {
					for e := 0; e < n; e += 1 {
						for f := 0; f < n; f += 1 {
							x += 1
						}
					}
				}
			}
		}
	}
	return i64(x)
}
