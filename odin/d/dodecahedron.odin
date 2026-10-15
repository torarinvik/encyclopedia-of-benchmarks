package dodecahedron

import "core:c"
import "core:math"

@(export)
dodecahedron :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	edge := values[0]
	quantity := values[1]
	if edge < 1 || edge > 1000000 || (quantity != 0 && quantity != 1) do return -1.0e300

	root_five := math.sqrt(5.0)
	if quantity == 0 {
		area_factor := 3.0 * math.sqrt(25.0 + 10.0 * root_five)
		return area_factor * f64(edge * edge)
	}
	volume_factor := (15.0 + 7.0 * root_five) / 4.0
	return volume_factor * f64(edge * edge * edge)
}
