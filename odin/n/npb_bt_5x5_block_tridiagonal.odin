package npb_bt_5x5_block_tridiagonal

import "core:c"
import "core:math"

BLOCK :: 5
MAX_LINE :: 4
ROW_WORDS :: 80
INVALID_RESULT :: -1.0e300

solve_block :: proc(matrix, right: [^]f64) -> (answer: [30]f64, ok: bool) {
	var work: [55]f64
	for r in 0..<BLOCK {
		for c in 0..<BLOCK { work[r*11+c] = matrix[r*5+c] }
		for c in 0..<6 { work[r*11+5+c] = right[r*6+c] }
	}
	for pivot in 0..<BLOCK {
		best := pivot
		for r in pivot+1..<BLOCK {
			if math.abs(work[r*11+pivot]) > math.abs(work[best*11+pivot]) { best = r }
		}
		if work[best*11+pivot] == 0 do return answer, false
		if best != pivot {
			for c in 0..<11 {
				temporary := work[pivot*11+c]
				work[pivot*11+c] = work[best*11+c]
				work[best*11+c] = temporary
			}
		}
		divisor := work[pivot*11+pivot]
		for c in pivot..<11 { work[pivot*11+c] /= divisor }
		for r in 0..<BLOCK {
			if r == pivot do continue
			factor := work[r*11+pivot]
			for c in pivot..<11 { work[r*11+c] -= factor * work[pivot*11+c] }
		}
	}
	for r in 0..<BLOCK { for c in 0..<6 { answer[r*6+c] = work[r*11+5+c] } }
	return answer, true
}

@(export)
npb_bt_5x5_block_tridiagonal :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 1 || length > c.size_t(1+ROW_WORDS*MAX_LINE) do return INVALID_RESULT
	if values[0] < 2 || values[0] > MAX_LINE do return INVALID_RESULT
	n := int(values[0])
	if length != c.size_t(1+ROW_WORDS*n) do return INVALID_RESULT

	var lower: [MAX_LINE][BLOCK][BLOCK]f64
	var diagonal: [MAX_LINE][BLOCK][BLOCK]f64
	var upper: [MAX_LINE][BLOCK][BLOCK]f64
	var rhs: [MAX_LINE][BLOCK]f64
	for row in 0..<n {
		cursor := 1+ROW_WORDS*row
		for which in 0..<3 {
			for r in 0..<BLOCK { for c in 0..<BLOCK {
				value := values[cursor]
				cursor += 1
				if which == 1 {
					if r == c {
						if value < 40 || value > 64 do return INVALID_RESULT
					} else if value < -2 || value > 2 do return INVALID_RESULT
					diagonal[row][r][c] = f64(value)
				} else {
					if value < -2 || value > 2 do return INVALID_RESULT
					if which == 0 { lower[row][r][c] = f64(value) }
				else { upper[row][r][c] = f64(value) }
				}
			} }
		}
		for r in 0..<BLOCK {
			value := values[cursor]
			cursor += 1
			if value < -1000 || value > 1000 do return INVALID_RESULT
			rhs[row][r] = f64(value)
		}
		for r in 0..<BLOCK { for c in 0..<BLOCK {
			if row == 0 && lower[row][r][c] != 0 do return INVALID_RESULT
			if row+1 == n && upper[row][r][c] != 0 do return INVALID_RESULT
		} }
		for r in 0..<BLOCK {
			off_diagonal := f64(0)
			for c in 0..<BLOCK {
				if r != c { off_diagonal += math.abs(diagonal[row][r][c]) }
				off_diagonal += math.abs(lower[row][r][c]) + math.abs(upper[row][r][c])
			}
			if diagonal[row][r][r] <= off_diagonal do return INVALID_RESULT
		}
	}

	var modified_upper: [MAX_LINE][BLOCK][BLOCK]f64
	var modified_rhs: [MAX_LINE][BLOCK]f64
	for row in 0..<n {
		var schur: [BLOCK][BLOCK]f64
		var reduced: [BLOCK]f64
		var right: [BLOCK][BLOCK+1]f64
		for r in 0..<BLOCK {
			reduced[r] = rhs[row][r]
			for c in 0..<BLOCK {
				schur[r][c] = diagonal[row][r][c]
				if row > 0 { for k in 0..<BLOCK { schur[r][c] -= lower[row][r][k]*modified_upper[row-1][k][c] } }
			}
			if row > 0 { for k in 0..<BLOCK { reduced[r] -= lower[row][r][k]*modified_rhs[row-1][k] } }
			for c in 0..<BLOCK { right[r][c] = upper[row][r][c] }
			right[r][BLOCK] = reduced[r]
		}
		solved, ok := solve_block(&schur[0][0], &right[0][0])
		if !ok do return INVALID_RESULT
		for r in 0..<BLOCK {
			modified_rhs[row][r] = solved[r*6+5]
			for c in 0..<BLOCK { modified_upper[row][r][c] = solved[r*6+c] }
		}
	}
	var solution: [MAX_LINE][BLOCK]f64
	for r in 0..<BLOCK { solution[n-1][r] = modified_rhs[n-1][r] }
	for row := n-1; row > 0; {
		row -= 1
		for r in 0..<BLOCK {
			solution[row][r] = modified_rhs[row][r]
			for c in 0..<BLOCK { solution[row][r] -= modified_upper[row][r][c]*solution[row+1][c] }
		}
	}
	checksum := f64(0)
	for row in 0..<n { for r in 0..<BLOCK { checksum += f64(row*BLOCK+r+1)*solution[row][r] } }
	return checksum
}
