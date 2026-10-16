module similarity_search

import math

fn put_u64_le(mut output &u8, offset int, value u64) {
	mut bits := value
	for b := 0; b < 8; b++ { unsafe { output[offset + b] = u8(bits & 255) }; bits >>= 8 }
}
fn put_i64_le(mut output &u8, offset int, value i64) { put_u64_le(mut output, offset, u64(value)) }
fn put_f64_le(mut output &u8, offset int, value f64) { put_u64_le(mut output, offset, math.bits_from_f64(value)) }

@[export: 'similarity_search']
pub fn similarity_search(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 643 { return -1 }
	unsafe {
		rv, qv, fv := input[0], input[1], input[2]
		if rv < 1 || rv > 32 || qv < 1 || qv > 8 || fv < 1 || fv > 16 { return -1 }
		rows, queries, features := int(rv), int(qv), int(fv)
		if length != usize(3 + (rows + queries) * features) { return -1 }
		for i := 0; i < (rows + queries) * features; i++ { if input[3+i] < -1000000 || input[3+i] > 1000000 { return -1 } }
		record := 16 + 8 * features
		needed := queries * record
		if output == nil || output_capacity < usize(needed) { return -2 }
		for query := 0; query < queries; query++ {
			mut best := 0
			mut sum := 0.0
			for f := 0; f < features; f++ {
				delta := f64(input[3+f])/1000000.0 - f64(input[3+rows*features+query*features+f])/1000000.0
				sum += delta * delta
			}
			mut best_distance := math.sqrt(sum)
			for row := 1; row < rows; row++ {
				sum = 0.0
				for f := 0; f < features; f++ {
					delta := f64(input[3+row*features+f])/1000000.0 - f64(input[3+rows*features+query*features+f])/1000000.0
					sum += delta * delta
				}
				distance := math.sqrt(sum)
				if distance < best_distance { best = row; best_distance = distance }
			}
			base := query * record
			put_i64_le(mut output, base, i64(best))
			put_f64_le(mut output, base + 8, best_distance)
			for f := 0; f < features; f++ { put_i64_le(mut output, base + 16 + 8*f, input[3+best*features+f]) }
		}
		return i64(needed)
	}
}
