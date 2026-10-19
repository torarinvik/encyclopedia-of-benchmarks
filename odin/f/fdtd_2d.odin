// PolyBench/C fdtd-2d bounded port. See benchmarks/f/fdtd_2d/LICENSE.txt.
package fdtd_2d
import "core:c"
import "core:math"

@(export)
fdtd_2d :: proc "c" (input: [^]f64, length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	tv,xv,yv := input[0],input[1],input[2]
	if tv!=tv||xv!=xv||yv!=yv||math.trunc(tv)!=tv||math.trunc(xv)!=xv||math.trunc(yv)!=yv||tv<0||tv>4||xv<1||xv>6||yv<1||yv>6 do return -1
	tmax,nx,ny := int(tv),int(xv),int(yv)
	n,required := nx*ny,3*nx*ny
	if output==nil||capacity<c.size_t(required) do return -2
	var ex:[36]f64
	var ey:[36]f64
	var hz:[36]f64
	var fict:[4]f64
	var staged:[108]f64
	for t:=0;t<tmax;t+=1 { fict[t]=f64(t) }
	for i:=0;i<nx;i+=1 { for j:=0;j<ny;j+=1 {
		ex[i*ny+j]=f64(i*(j+1))/f64(nx)
		ey[i*ny+j]=f64(i*(j+2))/f64(ny)
		hz[i*ny+j]=f64(i*(j+3))/f64(nx)
	} }
	for t:=0;t<tmax;t+=1 {
		for j:=0;j<ny;j+=1 { ey[j]=fict[t] }
		for i:=1;i<nx;i+=1 { for j:=0;j<ny;j+=1 { ey[i*ny+j]=ey[i*ny+j]-0.5*(hz[i*ny+j]-hz[(i-1)*ny+j]) } }
		for i:=0;i<nx;i+=1 { for j:=1;j<ny;j+=1 { ex[i*ny+j]=ex[i*ny+j]-0.5*(hz[i*ny+j]-hz[i*ny+j-1]) } }
		for i:=0;i<nx-1;i+=1 { for j:=0;j<ny-1;j+=1 { hz[i*ny+j]=hz[i*ny+j]-0.7*((ex[i*ny+j+1]-ex[i*ny+j])+(ey[(i+1)*ny+j]-ey[i*ny+j])) } }
	}
	for i:=0;i<n;i+=1 { staged[i]=ex[i];staged[n+i]=ey[i];staged[2*n+i]=hz[i] }
	for i:=0;i<required;i+=1 { output[i]=staged[i] }
	return i64(required)
}
