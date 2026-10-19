// PolyBench/C fdtd-2d bounded port. See benchmarks/f/fdtd_2d/LICENSE.txt.
import math

@[export: 'fdtd_2d']
pub fn fdtd_2d(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		tv := input[0]; xv := input[1]; yv := input[2]
		if !tv.is_finite() || !xv.is_finite() || !yv.is_finite() || math.trunc(tv)!=tv || math.trunc(xv)!=xv || math.trunc(yv)!=yv || tv<0 || tv>4 || xv<1 || xv>6 || yv<1 || yv>6 { return -1 }
		tmax,nx,ny:=int(tv),int(xv),int(yv)
		n,required:=nx*ny,3*nx*ny
		if output==nil || capacity<usize(required) { return -2 }
		mut ex:=[36]f64{}
		mut ey:=[36]f64{}
		mut hz:=[36]f64{}
		mut fict:=[4]f64{}
		mut staged:=[108]f64{}
		for t in 0..tmax { fict[t]=f64(t) }
		for i in 0..nx { for j in 0..ny {
			ex[i*ny+j]=f64(i*(j+1))/f64(nx)
			ey[i*ny+j]=f64(i*(j+2))/f64(ny)
			hz[i*ny+j]=f64(i*(j+3))/f64(nx)
		} }
		for t in 0..tmax {
			for j in 0..ny { ey[j]=fict[t] }
			for i in 1..nx { for j in 0..ny { ey[i*ny+j]=ey[i*ny+j]-0.5*(hz[i*ny+j]-hz[(i-1)*ny+j]) } }
			for i in 0..nx { for j in 1..ny { ex[i*ny+j]=ex[i*ny+j]-0.5*(hz[i*ny+j]-hz[i*ny+j-1]) } }
			for i in 0..nx-1 { for j in 0..ny-1 { hz[i*ny+j]=hz[i*ny+j]-0.7*((ex[i*ny+j+1]-ex[i*ny+j])+(ey[(i+1)*ny+j]-ey[i*ny+j])) } }
		}
		for i in 0..n { staged[i]=ex[i];staged[n+i]=ey[i];staged[2*n+i]=hz[i] }
		for i in 0..required { output[i]=staged[i] }
		return i64(required)
	}
}
