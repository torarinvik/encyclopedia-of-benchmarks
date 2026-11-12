module npb_bt_5x5_block_tridiagonal

import math

const block = 5
const max_line = 4
const row_words = 80
const invalid_result = -1.0e300

fn solve_block(matrix []f64, right []f64, mut answer []f64) bool {
	mut work := [55]f64{}
	for r in 0 .. block {
		for c in 0 .. block { work[r * 11 + c] = matrix[r * 5 + c] }
		for c in 0 .. 6 { work[r * 11 + 5 + c] = right[r * 6 + c] }
	}
	for pivot in 0 .. block {
		mut best := pivot
		for r in pivot + 1 .. block {
			if math.abs(work[r * 11 + pivot]) > math.abs(work[best * 11 + pivot]) { best = r }
		}
		if work[best * 11 + pivot] == 0.0 { return false }
		for c in 0 .. 11 {
			temporary := work[pivot * 11 + c]
			work[pivot * 11 + c] = work[best * 11 + c]
			work[best * 11 + c] = temporary
		}
		divisor := work[pivot * 11 + pivot]
		for c in pivot .. 11 { work[pivot * 11 + c] /= divisor }
		for r in 0 .. block {
			if r == pivot { continue }
			factor := work[r * 11 + pivot]
			for c in pivot .. 11 { work[r * 11 + c] -= factor * work[pivot * 11 + c] }
		}
	}
	for r in 0 .. block { for c in 0 .. 6 { answer[r * 6 + c] = work[r * 11 + 5 + c] } }
	return true
}

@[export: 'npb_bt_5x5_block_tridiagonal']
pub fn npb_bt_5x5_block_tridiagonal(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 1 || length > 321 { return invalid_result }
	unsafe {
		if values[0] < 2 || values[0] > max_line { return invalid_result }
		n := int(values[0])
		if length != usize(1 + row_words * n) { return invalid_result }
		mut lower := [100]f64{}
		mut diagonal := [100]f64{}
		mut upper := [100]f64{}
		mut rhs := [20]f64{}
		for row in 0 .. n {
			mut cursor := 1 + row_words * row
			for which in 0 .. 3 {
				for r in 0 .. block {
					for c in 0 .. block {
						value := values[cursor]
						cursor++
						if which == 1 {
							if r == c {
								if value < 40 || value > 64 { return invalid_result }
							} else if value < -2 || value > 2 { return invalid_result }
							diagonal[row * 25 + r * 5 + c] = f64(value)
						} else {
							if value < -2 || value > 2 { return invalid_result }
							if which == 0 { lower[row * 25 + r * 5 + c] = f64(value) }
							else { upper[row * 25 + r * 5 + c] = f64(value) }
						}
					}
				}
			}
			for r in 0 .. block {
				value := values[cursor]
				cursor++
				if value < -1000 || value > 1000 { return invalid_result }
				rhs[row * 5 + r] = f64(value)
			}
			for r in 0 .. block { for c in 0 .. block {
				if row == 0 && lower[row * 25 + r * 5 + c] != 0.0 { return invalid_result }
				if row + 1 == n && upper[row * 25 + r * 5 + c] != 0.0 { return invalid_result }
			} }
			for r in 0 .. block {
				mut off_diagonal := f64(0)
				for c in 0 .. block {
					if r != c { off_diagonal += math.abs(diagonal[row * 25 + r * 5 + c]) }
					off_diagonal += math.abs(lower[row * 25 + r * 5 + c]) + math.abs(upper[row * 25 + r * 5 + c])
				}
				if diagonal[row * 25 + r * 5 + r] <= off_diagonal { return invalid_result }
			}
		}

		mut modified_upper := [100]f64{}
		mut modified_rhs := [20]f64{}
		for row in 0 .. n {
			mut schur := [25]f64{}
			mut reduced := [5]f64{}
			mut right := [30]f64{}
			mut solved := [30]f64{}
			for r in 0 .. block {
				reduced[r] = rhs[row * 5 + r]
				for c in 0 .. block {
					value := diagonal[row * 25 + r * 5 + c]
					if row > 0 { for k in 0 .. block { value -= lower[row * 25 + r * 5 + k] * modified_upper[(row - 1) * 25 + k * 5 + c] } }
					schur[r * 5 + c] = value
				}
				if row > 0 { for k in 0 .. block { reduced[r] -= lower[row * 25 + r * 5 + k] * modified_rhs[(row - 1) * 5 + k] } }
				for c in 0 .. block { right[r * 6 + c] = upper[row * 25 + r * 5 + c] }
				right[r * 6 + 5] = reduced[r]
			}
			if !solve_block(schur[0..25], right[0..30], mut solved[0..30]) { return invalid_result }
			for r in 0 .. block {
				modified_rhs[row * 5 + r] = solved[r * 6 + 5]
				for c in 0 .. block { modified_upper[row * 25 + r * 5 + c] = solved[r * 6 + c] }
			}
		}
		mut solution := [20]f64{}
		for r in 0 .. block { solution[(n - 1) * 5 + r] = modified_rhs[(n - 1) * 5 + r] }
		mut row := n - 1
		for row > 0 {
			row--
			for r in 0 .. block {
				solution[row * 5 + r] = modified_rhs[row * 5 + r]
				for c in 0 .. block { solution[row * 5 + r] -= modified_upper[row * 25 + r * 5 + c] * solution[(row + 1) * 5 + c] }
			}
		}
		mut checksum := f64(0)
		for q in 0 .. n * block { checksum += f64(q + 1) * solution[q] }
		return checksum
	}
}
