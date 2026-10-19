package linpack_lu_solve
// ANSIbench LINPACK dgefa/dgesl profile; upstream source and stated modifications are public domain.
import "core:c"
import "core:math"

@(export)
linpack_lu_solve :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	invalid := -1.0e300
	if input == nil || length < 1 || length > 22 do return invalid
	raw_n := input[0]
	if raw_n < 2 || raw_n > 4 do return invalid
	n := int(raw_n)
	if length != c.size_t(1+n*n+n) do return invalid
	a: [16]f64
	b: [4]f64
	pivots: [4]int
	for i in 0..<n*n {
		v := input[1+i]
		if v < -8 || v > 8 do return invalid
		a[i] = f64(v)
	}
	for i in 0..<n {
		v := input[1+n*n+i]
		if v < -32 || v > 32 do return invalid
		b[i] = f64(v)
	}
	for k in 0..<n-1 {
		l := k
		maximum := math.abs(a[n*k+k])
		for i in 1..<n-k {
			candidate := math.abs(a[n*k+k+i])
			if candidate > maximum { l=k+i; maximum=candidate }
		}
		pivots[k]=l
		if a[n*k+l] != 0 {
			if l != k { a[n*k+l],a[n*k+k]=a[n*k+k],a[n*k+l] }
			factor := -1.0/a[n*k+k]
			for i in 0..<n-k-1 { a[n*k+k+1+i]=factor*a[n*k+k+1+i] }
			for j in k+1..<n {
				t := a[n*j+l]
				if l != k { a[n*j+l]=a[n*j+k]; a[n*j+k]=t }
				if t != 0 { for i in 0..<n-k-1 { a[n*j+k+1+i]=a[n*j+k+1+i]+t*a[n*k+k+1+i] } }
			}
		} else { return invalid }
	}
	pivots[n-1]=n-1
	if a[n*(n-1)+n-1] == 0 do return invalid
	for k in 0..<n-1 {
		l:=pivots[k]; t:=b[l]
		if l!=k { b[l]=b[k]; b[k]=t }
		if t != 0 { for i in 0..<n-k-1 { b[k+1+i]=b[k+1+i]+t*a[n*k+k+1+i] } }
	}
	for kb in 0..<n {
		k:=n-(kb+1); b[k]=b[k]/a[n*k+k]; t:=-b[k]
		if t != 0 { for i in 0..<k { b[i]=b[i]+t*a[n*k+i] } }
	}
	result:=0.0
	for i in 0..<n { result=result+f64(i+1)*b[i] }
	if !math.is_finite(result) do return invalid
	return result
}
