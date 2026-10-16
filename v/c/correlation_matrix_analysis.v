module main

import math

const observations = 4
const max_variables = 5
const max_pairs = 10

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'correlation_matrix_analysis']
pub fn correlation_matrix_analysis(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 22 { return -1 }
		if input[0] != observations || input[1] < 2 || input[1] > max_variables { return -1 }
		p := int(input[1])
		if int(length) != 2 + observations * p { return -1 }
		for index in 0 .. observations * p {
			if input[2 + index] < -1000 || input[2 + index] > 1000 { return -1 }
		}
		for column in 0 .. p {
			first := input[2 + column]
			mut varying := false
			for row in 1 .. observations { if input[2 + row * p + column] != first { varying = true } }
			if !varying { return -1 }
		}
		output_bytes := 32 * p * p + 48
		if output == nil || usize(output_bytes) > output_capacity { return -2 }

		mut means := [5]f64{}
		mut correlation := [25]f64{}
		mut raw := [25]f64{}
		mut bonf := [25]f64{}
		mut fdr := [25]f64{}
		for column in 0 .. p {
			for row in 0 .. observations { means[column] += f64(input[2 + row * p + column]) }
			means[column] /= f64(observations)
		}
		for index in 0 .. p * p {
			raw[index] = 1.0
			bonf[index] = 1.0
			fdr[index] = 1.0
		}
		for index in 0 .. p { correlation[index * p + index] = 1.0 }

		mut pair_i := [10]int{}
		mut pair_j := [10]int{}
		mut pair_p := [10]f64{}
		mut pair_count := 0
		for j in 1 .. p {
			for i in 0 .. j {
				mut cross := 0.0
				mut sum_i := 0.0
				mut sum_j := 0.0
				for row in 0 .. observations {
					dx := f64(input[2 + row * p + i]) - means[i]
					dy := f64(input[2 + row * p + j]) - means[j]
					cross += dx * dy
					sum_i += dx * dx
					sum_j += dy * dy
				}
				r := cross / math.sqrt(sum_i * sum_j)
				pv := 1.0 - math.abs(r)
				correlation[i * p + j] = r
				correlation[j * p + i] = r
				raw[i * p + j] = pv
				raw[j * p + i] = pv
				pair_i[pair_count] = i
				pair_j[pair_count] = j
				pair_p[pair_count] = pv
				pair_count++
			}
		}
		for k in 0 .. pair_count {
			mut adjusted := pair_p[k] * f64(pair_count)
			if adjusted > 1.0 { adjusted = 1.0 }
			i := pair_i[k]
			j := pair_j[k]
			bonf[i * p + j] = adjusted
			bonf[j * p + i] = adjusted
		}
		mut order := [10]int{}
		for k in 0 .. pair_count { order[k] = k }
		for k in 1 .. pair_count {
			value := order[k]
			mut at := k
			for at > 0 && pair_p[order[at - 1]] > pair_p[value] {
				order[at] = order[at - 1]
				at--
			}
			order[at] = value
		}
		mut running := 1.0
		for pos := pair_count - 1; pos >= 0; pos-- {
			mut adjusted := pair_p[order[pos]] * f64(pair_count) / f64(pos + 1)
			if adjusted > 1.0 { adjusted = 1.0 }
			if adjusted < running { running = adjusted }
			k := order[pos]
			i := pair_i[k]
			j := pair_j[k]
			fdr[i * p + j] = running
			fdr[j * p + i] = running
		}
		mut sig_raw := i64(0)
		mut sig_bonf := i64(0)
		mut sig_fdr := i64(0)
		for k in 0 .. pair_count {
			i := pair_i[k]
			j := pair_j[k]
			if pair_p[k] < 0.05 { sig_raw++ }
			if bonf[i * p + j] < 0.05 { sig_bonf++ }
			if fdr[i * p + j] < 0.05 { sig_fdr++ }
		}
		mut offset := 0
		for index in 0 .. p * p { put_f64_le(mut output, offset, correlation[index]); offset += 8 }
		for index in 0 .. p * p { put_f64_le(mut output, offset, raw[index]); offset += 8 }
		for index in 0 .. p * p { put_f64_le(mut output, offset, bonf[index]); offset += 8 }
		for index in 0 .. p * p { put_f64_le(mut output, offset, fdr[index]); offset += 8 }
		for value in [i64(observations), i64(p), i64(0), sig_raw, sig_bonf, sig_fdr] {
			put_i64_le(mut output, offset, value)
			offset += 8
		}
		return i64(offset)
	}
}
