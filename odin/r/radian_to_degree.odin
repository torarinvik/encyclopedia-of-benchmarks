package radian_to_degree

@(export)
radian_to_degree :: proc "c" (radian: f64) -> f64 {
	if !(radian >= -1_000_000.0 && radian <= 1_000_000.0) do return -1.0e300
	return radian * (180.0 / 3.141592653589793)
}
