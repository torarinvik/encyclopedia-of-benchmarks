module decimal_isolate

@[export: 'decimal_isolate']
pub fn decimal_isolate(input f64) f64 {
	if !(input > 0.0 && input <= 999_999.0) { return -1.0 }
	scaled_value := input * 10_000.0
	scaled := i64(scaled_value)
	if f64(scaled) != scaled_value || f64(scaled) / 10_000.0 != input { return -1.0 }
	if scaled % 625 != 0 || scaled % 10_000 == 0 { return -1.0 }
	return f64(scaled % 10_000) / 10_000.0
}
