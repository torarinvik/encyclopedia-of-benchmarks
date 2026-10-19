// PolyBench/C heat-3d bounded port. See benchmarks/h/heat_3d/LICENSE.txt.
package heat_3d
import "core:c"
import "core:math"

@(export)
polybench_heat_3d :: proc "c" (input: [^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
	if input==nil||length!=2 do return -1
	nv,sv:=input[0],input[1]
	if nv!=nv||sv!=sv||math.trunc(nv)!=nv||math.trunc(sv)!=sv||nv<1||nv>6||sv<0||sv>4 do return -1
	n,steps:=int(nv),int(sv);cells:=n*n*n
	if output==nil||capacity<c.size_t(cells) do return -2
	var a:[216]f64
	var b:[216]f64
	var staged:[216]f64
	for i:=0;i<n;i+=1 { for j:=0;j<n;j+=1 { for k:=0;k<n;k+=1 {
		q:=i*n*n+j*n+k;a[q]=f64(i+j+(n-k))*10.0/f64(n);b[q]=a[q]
	} } }
	for step:=0;step<steps;step+=1 {
		for i:=1;i<n-1;i+=1 { for j:=1;j<n-1;j+=1 { for k:=1;k<n-1;k+=1 {
			q:=i*n*n+j*n+k;c0:=a[q]
			b[q]=0.125*(a[q+n*n]-2.0*c0+a[q-n*n])+0.125*(a[q+n]-2.0*c0+a[q-n])+0.125*(a[q+1]-2.0*c0+a[q-1])+c0
		} } }
		for i:=1;i<n-1;i+=1 { for j:=1;j<n-1;j+=1 { for k:=1;k<n-1;k+=1 {
			q:=i*n*n+j*n+k;c0:=b[q]
			a[q]=0.125*(b[q+n*n]-2.0*c0+b[q-n*n])+0.125*(b[q+n]-2.0*c0+b[q-n])+0.125*(b[q+1]-2.0*c0+b[q-1])+c0
		} } }
	}
	for q:=0;q<cells;q+=1 { staged[q]=a[q] }
	for q:=0;q<cells;q+=1 { output[q]=staged[q] }
	return i64(cells)
}
