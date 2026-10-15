package ohms_law

@(export)
ohms_law :: proc "c" (voltage, current, resistance: f64) -> f64 {
	if voltage != voltage || current != current || resistance != resistance do return -1e300
	if voltage < -1000.0 || voltage > 1000.0 || current < -1000.0 || current > 1000.0 || resistance < 0.0 || resistance > 1000.0 do return -1e300
	if voltage != f64(i64(voltage)) || current != f64(i64(current)) || resistance != f64(i64(resistance)) do return -1e300
	zeros := 0
	if voltage == 0.0 do zeros += 1
	if current == 0.0 do zeros += 1
	if resistance == 0.0 do zeros += 1
	if zeros != 1 do return -1e300
	if voltage == 0.0 do return current * resistance
	if current == 0.0 do return voltage / resistance
	return voltage / current
}
