package one_sided_jacobi_svd

import "core:c"
import "core:math"

@(export)
one_sided_jacobi_svd :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 39 do return -1
	m64, n64 := input[0], input[1]
	if n64 < 1 || n64 > 6 || m64 < n64 || m64 > 6 do return -1
	m, n := int(m64), int(n64)
	if int(length) != 2 + m*n do return -1
	a: [36]f64
	for r := 0; r < m; r += 1 {
		for col := 0; col < n; col += 1 {
			x := input[2+r*n+col]
			if x < -8 || x > 8 do return -1
			a[r*n+col] = f64(x)
		}
	}
	converged := false
	for sweep := 0; sweep < 128; sweep += 1 {
		changed := false
		for p := 0; p < n; p += 1 {
			for q := p+1; q < n; q += 1 {
				alpha, beta, gamma := f64(0), f64(0), f64(0)
				for r := 0; r < m; r += 1 { x, y := a[r*n+p], a[r*n+q]; alpha += x*x; beta += y*y; gamma += x*y }
				if alpha == 0 || beta == 0 || math.abs(gamma) <= 1e-14*math.sqrt_f64(alpha*beta) do continue
				tau := (beta-alpha)/(2*gamma)
				t := f64(1)
				if tau != 0 { sign := f64(1); if tau < 0 do sign = -1; t = sign/(math.abs(tau)+math.sqrt_f64(1+tau*tau)) }
				cval := 1/math.sqrt_f64(1+t*t); sval := cval*t
				for r := 0; r < m; r += 1 { x,y := a[r*n+p],a[r*n+q];a[r*n+p]=cval*x-sval*y;a[r*n+q]=sval*x+cval*y }
				changed = true
			}
		}
		if !changed { converged = true; break }
	}
	if !converged do return -1
	sigma: [6]f64
	for col := 0; col < n; col += 1 { for r := 0; r < m; r += 1 { sigma[col] += a[r*n+col]*a[r*n+col] }; sigma[col] = math.sqrt_f64(sigma[col]) }
	for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 { if sigma[j] > sigma[i] { sigma[i],sigma[j]=sigma[j],sigma[i] } } }
	signature := f64(0)
	for i := 0; i < n; i += 1 { signature += f64(i+1)*sigma[i] }
	return i64(signature*1000+0.5)
}
