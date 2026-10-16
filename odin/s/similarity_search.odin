package similarity_search

import "core:c"
import "core:math"

put_u64 :: proc "contextless" (output: [^]u8, offset: int, value: u64) {
	for b := 0; b < 8; b += 1 { output[offset+b] = u8(value >> u64(8*b)) }
}
put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) { put_u64(output, offset, transmute(u64)value) }
put_f64 :: proc "contextless" (output: [^]u8, offset: int, value: f64) { put_u64(output, offset, transmute(u64)value) }

@(export)
similarity_search :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 643 do return -1
	rv, qv, fv := input[0], input[1], input[2]
	if rv < 1 || rv > 32 || qv < 1 || qv > 8 || fv < 1 || fv > 16 do return -1
	rows, queries, features := int(rv), int(qv), int(fv)
	if int(length) != 3 + (rows + queries) * features do return -1
	for i := 0; i < (rows + queries) * features; i += 1 { if input[3+i] < -1000000 || input[3+i] > 1000000 do return -1 }
	record := 16 + 8 * features
	needed := queries * record
	if output == nil || output_capacity < c.size_t(needed) do return -2
	for query := 0; query < queries; query += 1 {
		best := 0
		sum := f64(0)
		for f := 0; f < features; f += 1 {
			delta := f64(input[3+f])/1000000.0 - f64(input[3+rows*features+query*features+f])/1000000.0
			sum += delta * delta
		}
		best_distance := math.sqrt(sum)
		for row := 1; row < rows; row += 1 {
			sum = 0
			for f := 0; f < features; f += 1 {
				delta := f64(input[3+row*features+f])/1000000.0 - f64(input[3+rows*features+query*features+f])/1000000.0
				sum += delta * delta
			}
			distance := math.sqrt(sum)
			if distance < best_distance { best = row; best_distance = distance }
		}
		base := query * record
		put_i64(output, base, i64(best))
		put_f64(output, base+8, best_distance)
		for f := 0; f < features; f += 1 { put_i64(output, base+16+8*f, input[3+best*features+f]) }
	}
	return i64(needed)
}
