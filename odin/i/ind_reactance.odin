package ind_reactance

import "core:c"

@(export)
ind_reactance :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	inductance := values[0]
	frequency := values[1]
	reactance := values[2]
	if inductance < 0 || inductance > 1000 || frequency < 0 || frequency > 1000 || reactance < 0 || reactance > 1000 do return -1.0e300
	zeros := 0
	if inductance == 0 do zeros += 1
	if frequency == 0 do zeros += 1
	if reactance == 0 do zeros += 1
	if zeros != 1 do return -1.0e300
	pi: f64 = 3.14159265358979323846
	if inductance == 0 do return f64(reactance) / (2.0 * pi * f64(frequency))
	if frequency == 0 do return f64(reactance) / (2.0 * pi * f64(inductance))
	return 2.0 * pi * f64(frequency) * f64(inductance)
}
