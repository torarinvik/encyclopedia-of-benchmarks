package capacitor_equivalence

import "core:c"

@(export)
capacitor_equivalence :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 || length > 33 do return -1.0e300
	operation := values[0]
	if operation != 0 && operation != 1 do return -1.0e300
	accumulated := f64(0.0)
	for index in 1..<length {
		capacitor := values[index]
		if (operation == 0 && capacitor < 0) || (operation == 1 && capacitor < 1) || capacitor > 1000 do return -1.0e300
		if operation == 0 do accumulated += f64(capacitor)
		else do accumulated += 1.0 / f64(capacitor)
	}
	if operation == 0 do return accumulated
	return 1.0 / accumulated
}
