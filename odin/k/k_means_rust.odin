package k_means_rust

import "core:c"

U53_MAX :: i64(9007199254740991)
U53_DENOMINATOR :: f64(9007199254740992.0)

@(export)
k_means_rust :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 10 || input[0] != 4 do return -1
	max_iter := input[1]
	if max_iter < 1 || max_iter > 16 do return -1
	draw0, draw1 := input[2], input[4]
	if input[3] != 0 || input[5] != 0 || draw0 < 0 || draw0 > U53_MAX ||
		draw1 < 0 || draw1 > U53_MAX || draw0 == draw1 do return -1

	var points: [4]f64
	for index := 0; index < 4; index += 1 {
		coordinate := input[index+6]
		if coordinate < -16 || coordinate > 16 || (index > 0 && input[index+5] >= coordinate) do return -1
		points[index] = f64(coordinate)
	}
	if input[7] >= 0 || input[8] <= 1 do return -1

	var centers := [2][2]f64{{f64(draw0)/U53_DENOMINATOR, 0.0}, {f64(draw1)/U53_DENOMINATOR, 0.0}}
	var labels: [4]i64
	for _ in 0 ..< int(max_iter) {
		var sums: [2][2]f64
		var counts: [2]int
		for index := 0; index < 4; index += 1 {
			dx0 := points[index] - centers[0][0]
			dy0 := -centers[0][1]
			dx1 := points[index] - centers[1][0]
			dy1 := -centers[1][1]
			distance0 := dx0*dx0 + dy0*dy0
			distance1 := dx1*dx1 + dy1*dy1
			cluster := 0
			if distance1 < distance0 do cluster = 1
			labels[index] = i64(cluster)
			sums[cluster][0] += points[index]
			sums[cluster][1] += 0.0
			counts[cluster] += 1
		}
		if counts[0] == 0 || counts[1] == 0 do return -1
		for cluster := 0; cluster < 2; cluster += 1 {
			centers[cluster][0] = sums[cluster][0] / f64(counts[cluster])
			centers[cluster][1] = sums[cluster][1] / f64(counts[cluster])
		}
	}

	packed := i64(0)
	for index := 0; index < 4; index += 1 { packed += labels[index] * (i64(1) << index) }
	return packed
}
