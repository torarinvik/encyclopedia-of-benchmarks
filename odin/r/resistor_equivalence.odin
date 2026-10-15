package resistor_equivalence

import "core:c"

@(export)
resistor_equivalence :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 || length > 33 do return -1.0e300
	operation := values[0]
	if operation != 0 && operation != 1 do return -1.0e300
	accumulated: f64 = 0.0
	for index in 1..<length {
		resistor := values[index]
		if (operation == 0 && resistor < 1) || (operation == 1 && resistor < 0) || resistor > 1000 do return -1.0e300
		if operation == 0 do accumulated += 1.0 / f64(resistor)
		else do accumulated += f64(resistor)
	}
	if operation == 0 do return 1.0 / accumulated
	return accumulated
}
