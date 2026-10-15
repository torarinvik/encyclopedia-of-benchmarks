package babylonian_method

@(export)
babylonian_method :: proc "c" (input: f64) -> f64 {
	if !(input >= 2.0 && input <= 999_999.0) do return -1.0
	radicand := i64(input)
	if f64(radicand) != input do return -1.0
	i: i64 = 1
	for i * i <= radicand { i += 1 }
	i -= 1
	if i * i == radicand do return -1.0
	x0 := f64(i)
	return (input / x0 + x0) / 2.0
}
