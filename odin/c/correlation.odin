package correlation

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
DELTA :: 1.0e-9

@(export)
correlation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 3 do return INVALID_RESULT
	n_value := values[0]
	if n_value < 1 || n_value > 128 || length != 1 + 2*c.size_t(n_value) do return INVALID_RESULT
	n := int(n_value)
	exy, ex, exx, ey, eyy: f64 = 0.0, 0.0, 0.0, 0.0, 0.0
	for i in 0..<n {
		xi := values[1+i]
		yi := values[1+n+i]
		if xi < -1000 || xi > 1000 || yi < -1000 || yi > 1000 do return INVALID_RESULT
		x, y := f64(xi), f64(yi)
		exy += x*y
		ex += x
		exx += x*x
		ey += y
		eyy += y*y
	}
	exy /= f64(n)
	ex /= f64(n)
	exx /= f64(n)
	ey /= f64(n)
	eyy /= f64(n)
	cov := exy - ex*ey
	varx := math.sqrt_f64(exx-ex*ex)
	vary := math.sqrt_f64(eyy-ey*ey)
	if varx*vary < DELTA do return 0.0
	return cov / math.sqrt_f64(varx*vary)
}
