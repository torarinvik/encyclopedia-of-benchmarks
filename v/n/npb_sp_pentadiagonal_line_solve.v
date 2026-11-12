import math

const min_n = 5.0
const max_n = 16.0

@[export: 'npb_sp_pentadiagonal_line_solve']
pub fn npb_sp_pentadiagonal_line_solve(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 31 || length > 97 { return -1 }
		nv := input[0]
		if nv != nv || math.trunc(nv) != nv || nv < min_n || nv > max_n { return -1 }
		n := int(nv)
		if length != usize(1 + 6*n) { return -1 }
		lower2 := input[1..1+n]
		lower1 := input[1+n..1+2*n]
		diagonal := input[1+2*n..1+3*n]
		upper1 := input[1+3*n..1+4*n]
		upper2 := input[1+4*n..1+5*n]
		rhs := input[1+5*n..1+6*n]
		if lower2[0] != 0 || lower2[1] != 0 || lower1[0] != 0 || upper1[n-1] != 0 || upper2[n-2] != 0 || upper2[n-1] != 0 { return -1 }
		for row in 0 .. n {
			bands := [4]f64{lower2[row], lower1[row], upper1[row], upper2[row]}
			mut radius := 0.0
			for band in bands {
				if band != band || math.abs(band) > 2.0 { return -1 }
				radius += math.abs(band)
			}
			if diagonal[row] != diagonal[row] || diagonal[row] < 5.0 || diagonal[row] > 16.0 || rhs[row] != rhs[row] || rhs[row] < -64.0 || rhs[row] > 64.0 || diagonal[row]-radius < 0.25 { return -1 }
		}
		if isnil(output) || capacity < usize(n) { return -2 }
		mut lo1 := []f64{len: max_n}
		mut diag := []f64{len: max_n}
		mut up1 := []f64{len: max_n}
		mut up2 := []f64{len: max_n}
		mut work_rhs := []f64{len: max_n}
		mut solution := []f64{len: max_n}
		for row in 0 .. n {
			lo1[row] = lower1[row]; diag[row] = diagonal[row]
			up1[row] = upper1[row]; up2[row] = upper2[row]; work_rhs[row] = rhs[row]
		}
		for pivot_row in 0 .. n {
			pivot := diag[pivot_row]
			if pivot_row+1 < n {
				row := pivot_row+1
				factor := lo1[row]/pivot
				diag[row] -= factor*up1[pivot_row]
				up1[row] -= factor*up2[pivot_row]
				work_rhs[row] -= factor*work_rhs[pivot_row]
			}
			if pivot_row+2 < n {
				row := pivot_row+2
				factor := lower2[row]/pivot
				lo1[row] -= factor*up1[pivot_row]
				diag[row] -= factor*up2[pivot_row]
				work_rhs[row] -= factor*work_rhs[pivot_row]
			}
		}
		mut back := n
		for back > 0 {
			back--
			mut value := work_rhs[back]
			if back+1 < n { value -= up1[back]*solution[back+1] }
			if back+2 < n { value -= up2[back]*solution[back+2] }
			solution[back] = value/diag[back]
		}
		for row in 0 .. n { output[row] = solution[row] }
		return i64(n)
	}
}
