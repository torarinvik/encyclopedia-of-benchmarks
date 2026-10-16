package vector2

import "core:c"
import "core:math"

@(export)
vector2 :: proc "c" (values: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if values == nil || length != c.size_t(6) do return -1
	for i := 0; i < 6; i += 1 {
		if values[i] != values[i] || values[i] > 1e100 || values[i] < -1e100 do return -1
	}
	if values[0] < 0.0 || values[0] > 10.0 || values[0] != math.floor_f64(values[0]) do return -1
	for i := 1; i <= 4; i += 1 {
		if values[i] < -1000.0 || values[i] > 1000.0 do return -1
	}
	op := int(values[0])
	ax, ay, bx, by, scalar := values[1], values[2], values[3], values[4], values[5]
	if op == 1 {
		if scalar < 0.0 || scalar > 2000.0 do return -1
	} else if op == 6 {
		if bx != 0.0 || by != 0.0 || scalar < -1000.0 || scalar > 1000.0 do return -1
	} else if op == 9 {
		if bx != 0.0 || by != 0.0 || scalar < -6.283185307179586 || scalar > 6.283185307179586 do return -1
	} else if scalar != 0.0 do return -1
	if (op == 2 || op == 3) && (bx != 0.0 || by != 0.0) do return -1

	result := [2]f64{0.0, 0.0}
	result_length := 1
	if op == 0 {
		if ax == bx && ay == by do result[0] = 1.0
	} else if op == 1 {
		if math.abs(ax-bx) < scalar && math.abs(ay-by) < scalar do result[0] = 1.0
	} else if op == 2 {
		result[0] = math.sqrt(ax*ax + ay*ay)
	} else if op == 3 {
		magnitude := math.sqrt(ax*ax + ay*ay)
		if magnitude == 0.0 do return -1
		result_length = 2
		result[0], result[1] = ax/magnitude, ay/magnitude
	} else if op == 4 {
		result_length = 2
		result[0], result[1] = ax+bx, ay+by
	} else if op == 5 {
		result_length = 2
		result[0], result[1] = ax-bx, ay-by
	} else if op == 6 {
		result_length = 2
		result[0], result[1] = ax*scalar, ay*scalar
	} else if op == 7 {
		dx, dy := bx-ax, by-ay
		result[0] = math.sqrt(dx*dx + dy*dy)
	} else if op == 8 {
		result[0] = ax*bx + ay*by
	} else if op == 9 {
		cosine, sine := math.cos(scalar), math.sin(scalar)
		result_length = 2
		result[0], result[1] = cosine*ax-sine*ay, sine*ax+cosine*ay
	} else {
		result[0] = math.atan2(by, bx) - math.atan2(ay, ax)
	}
	if output == nil || capacity < c.size_t(result_length) do return -2
	for i := 0; i < result_length; i += 1 { output[i] = result[i] }
	return i64(result_length)
}
