package splash2_water_nsquared

import "core:c"

MAX_N :: 64
MAX_PARSEABLE :: 260
MAX_OUTPUT_WORDS :: 194
SCALE :: i64(1_000_000)

trunc_div :: proc "contextless" (numerator, denominator: i64) -> i64 {
	if numerator < 0 { return -((-numerator) / denominator) }
	return numerator / denominator
}

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
splash2_water_nsquared :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_PARSEABLE) do return -1
	n_raw, grid, radius := input[0], input[1], input[2]
	if n_raw < 0 || n_raw > MAX_N || grid < 1 || grid > 8 || radius < 1 || radius > 4 do return -1
	n := int(n_raw)
	if length != c.size_t(3 + 4 * n) do return -1
	side, radius2 := grid * radius, radius * radius
	var x, y, z, charge: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		at := 3 + 4 * i
		x[i], y[i], z[i], charge[i] = input[at], input[at+1], input[at+2], input[at+3]
		if x[i] < 0 || x[i] >= side || y[i] < 0 || y[i] >= side || z[i] < 0 || z[i] >= side || charge[i] < -4 || charge[i] > 4 do return -1
	}
	var force: [MAX_N][3]i64
	energy, pairs: i64 = 0, 0
	for i := 0; i < n; i += 1 {
		for j := i + 1; j < n; j += 1 {
			dx, dy, dz := x[j]-x[i], y[j]-y[i], z[j]-z[i]
			r2 := dx*dx + dy*dy + dz*dz
			if r2 >= radius2 do continue
			product := charge[i] * charge[j]
			energy += trunc_div(product*(radius2-r2)*SCALE, (1+r2)*(1+radius2))
			denominator := (1+r2)*(1+r2)
			fx := trunc_div(-2*product*dx*SCALE, denominator)
			fy := trunc_div(-2*product*dy*SCALE, denominator)
			fz := trunc_div(-2*product*dz*SCALE, denominator)
			force[i][0] += fx; force[i][1] += fy; force[i][2] += fz
			force[j][0] -= fx; force[j][1] -= fy; force[j][2] -= fz
			pairs += 1
		}
	}
	words := 3*n + 2
	bytes := words * 8
	if output == nil || capacity < c.size_t(bytes) do return -2
	var result: [MAX_OUTPUT_WORDS]i64
	for i := 0; i < n; i += 1 { for axis := 0; axis < 3; axis += 1 { result[3*i+axis] = force[i][axis] } }
	result[3*n], result[3*n+1] = energy, pairs
	for word := 0; word < words; word += 1 { store_le(output, 8*word, result[word]) }
	return i64(bytes)
}
