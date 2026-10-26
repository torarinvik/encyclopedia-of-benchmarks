// Clean-room bounded PolyBench QR port. See package LICENSE.txt.
import math

@[export: 'polybench_gramschmidt']
pub fn polybench_gramschmidt(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		mv, nv := input[0], input[1]
		if !mv.is_finite() || !nv.is_finite() || math.trunc(mv) != mv || math.trunc(nv) != nv || mv < 1 || mv > 6 || nv < 1 || nv > 6 || nv > mv { return -1 }
		m, n := int(mv), int(nv)
		q_cells, r_cells := m*n, n*n
		total := q_cells+r_cells
		if output == nil || capacity < usize(total) { return -2 }
		mut a := [36]f64{}
		mut q := [36]f64{}
		mut r := [36]f64{}
		mut staged := [72]f64{}
		for i in 0 .. m { for j in 0 .. n { a[i*n+j] = f64((i*j)%m)/f64(m)*100.0+10.0 } }
		for k in 0 .. n {
			mut norm_squared := 0.0
			for i in 0 .. m { norm_squared += a[i*n+k]*a[i*n+k] }
			r[k*n+k] = math.sqrt(norm_squared)
			for i in 0 .. m { q[i*n+k] = a[i*n+k]/r[k*n+k] }
			for j in (k+1) .. n {
				r[k*n+j] = 0.0
				for i in 0 .. m { r[k*n+j] += q[i*n+k]*a[i*n+j] }
				for i in 0 .. m { a[i*n+j] = a[i*n+j]-q[i*n+k]*r[k*n+j] }
			}
		}
		for x in 0 .. r_cells { staged[x] = r[x] }
		for x in 0 .. q_cells { staged[r_cells+x] = q[x] }
		for x in 0 .. total { output[x] = staged[x] }
		return i64(total)
	}
}
