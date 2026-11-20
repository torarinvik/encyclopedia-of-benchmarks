module one_sided_jacobi_svd

import math

@[export: 'one_sided_jacobi_svd']
pub fn one_sided_jacobi_svd(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 39 { return -1 }
		m64, n64 := input[0], input[1]
		if n64 < 1 || n64 > 6 || m64 < n64 || m64 > 6 { return -1 }
		m, n := int(m64), int(n64)
		if length != usize(2 + m*n) { return -1 }
		mut a := [36]f64{}
		for r in 0 .. m {
			for col in 0 .. n {
				x := input[2+r*n+col]
				if x < -8 || x > 8 { return -1 }
				a[r*n+col] = f64(x)
			}
		}
		mut converged := false
		for _ in 0 .. 128 {
			mut changed := false
			for p in 0 .. n {
				for q in p+1 .. n {
					mut alpha, beta, gamma := f64(0), f64(0), f64(0)
					for r in 0 .. m { x,y := a[r*n+p],a[r*n+q]; alpha+=x*x;beta+=y*y;gamma+=x*y }
					if alpha == 0 || beta == 0 || math.abs(gamma) <= 1e-14*math.sqrt(alpha*beta) { continue }
					tau := (beta-alpha)/(2*gamma)
					t := f64(1)
					if tau != 0 { sign := if tau > 0 { f64(1) } else { f64(-1) }; t=sign/(math.abs(tau)+math.sqrt(1+tau*tau)) }
					c := 1/math.sqrt(1+t*t);s:=c*t
					for r in 0 .. m { x,y:=a[r*n+p],a[r*n+q];a[r*n+p]=c*x-s*y;a[r*n+q]=s*x+c*y }
					changed=true
				}
			}
			if !changed { converged=true;break }
		}
		if !converged { return -1 }
		mut sigma := [6]f64{}
		for col in 0 .. n { for r in 0 .. m { sigma[col]+=a[r*n+col]*a[r*n+col] };sigma[col]=math.sqrt(sigma[col]) }
		for i in 0 .. n { for j in i+1 .. n { if sigma[j]>sigma[i] { sigma[i],sigma[j]=sigma[j],sigma[i] } } }
		mut signature:=f64(0)
		for i in 0 .. n { signature+=f64(i+1)*sigma[i] }
		return i64(signature*1000+0.5)
	}
}
