module linpack_lu_solve
// ANSIbench LINPACK dgefa/dgesl profile; upstream source and stated modifications are public domain.
import math

@[export: 'linpack_lu_solve']
pub fn linpack_lu_solve(input &i64, length usize) f64 {
	invalid := -1e300
	if unsafe { input == nil } || length < 1 || length > 22 { return invalid }
	n64 := unsafe { input[0] }
	if n64 < 2 || n64 > 4 { return invalid }
	n := int(n64)
	if length != usize(1+n*n+n) { return invalid }
	mut a := []f64{len: 16}
	mut b := []f64{len: 4}
	mut pivots := []int{len: 4}
	for i in 0 .. n*n {
		v := unsafe { input[1+i] }
		if v < -8 || v > 8 { return invalid }
		a[i] = f64(v)
	}
	for i in 0 .. n {
		v := unsafe { input[1+n*n+i] }
		if v < -32 || v > 32 { return invalid }
		b[i] = f64(v)
	}
	for k in 0 .. n-1 {
		mut l := k
		mut maximum := math.abs(a[n*k+k])
		for i in 1 .. n-k {
			candidate := math.abs(a[n*k+k+i])
			if candidate > maximum { l=k+i; maximum=candidate }
		}
		pivots[k]=l
		if a[n*k+l] == 0 { return invalid }
		if l != k { a[n*k+l], a[n*k+k] = a[n*k+k], a[n*k+l] }
		factor := -1.0/a[n*k+k]
		for i in 0 .. n-k-1 { a[n*k+k+1+i]=factor*a[n*k+k+1+i] }
		for j in k+1 .. n {
			mut t := a[n*j+l]
			if l != k { a[n*j+l]=a[n*j+k]; a[n*j+k]=t }
			if t != 0 { for i in 0 .. n-k-1 { a[n*j+k+1+i]=a[n*j+k+1+i]+t*a[n*k+k+1+i] } }
		}
	}
	pivots[n-1]=n-1
	if a[n*(n-1)+n-1] == 0 { return invalid }
	for k in 0 .. n-1 {
		l:=pivots[k]; mut t:=b[l]
		if l!=k { b[l]=b[k]; b[k]=t }
		if t != 0 { for i in 0 .. n-k-1 { b[k+1+i]=b[k+1+i]+t*a[n*k+k+1+i] } }
	}
	for kb in 0 .. n {
		k:=n-(kb+1); b[k]=b[k]/a[n*k+k]; t:=-b[k]
		if t != 0 { for i in 0 .. k { b[i]=b[i]+t*a[n*k+i] } }
	}
	mut result := 0.0
	for i in 0 .. n { result=result+f64(i+1)*b[i] }
	if !math.is_finite(result) { return invalid }
	return result
}
