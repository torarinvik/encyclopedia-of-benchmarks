module pressure

fn to_pascal_factor(code f64) f64 {
	if code == 0.0 { return 1.0 }
	if code == 1.0 { return 1000.0 }
	if code == 2.0 { return 1000000.0 }
	if code == 3.0 { return 100000.0 }
	if code == 4.0 { return 101325.0 }
	if code == 5.0 { return 6894.757293168 }
	return 0.0
}

@[export: 'pressure']
pub fn pressure(value f64, from_unit_code f64, to_unit_code f64) f64 {
	if value != value || value < -1000000.0 || value > 1000000.0 { return -1.0 }
	from_factor := to_pascal_factor(from_unit_code)
	to_factor := to_pascal_factor(to_unit_code)
	if from_factor == 0.0 || to_factor == 0.0 { return -1.0 }
	pascals := value * from_factor
	return pascals / to_factor
}
