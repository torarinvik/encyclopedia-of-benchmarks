module babylonian_method

@[export: 'babylonian_method']
pub fn babylonian_method(input f64) f64 {
	if !(input >= 2.0 && input <= 999_999.0) { return -1.0 }
	radical := i64(input)
	if f64(radical) != input { return -1.0 }
	mut i := i64(1)
	for i * i <= radical { i++ }
	i--
	if i * i == radical { return -1.0 }
	x0 := f64(i)
	return (input / x0 + x0) / 2.0
}
