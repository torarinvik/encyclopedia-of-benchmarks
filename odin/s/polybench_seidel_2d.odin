// PolyBench/C seidel-2d bounded port. See benchmarks/s/polybench_seidel_2d/LICENSE.txt.
package polybench_seidel_2d
import "core:c"
import "core:math"

@(export)
polybench_seidel_2d :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
	if input==nil||length!=2 do return -1
	nv,sv:=input[0],input[1]
	if nv!=nv||sv!=sv||math.trunc(nv)!=nv||math.trunc(sv)!=sv||nv<1||nv>6||sv<0||sv>4 do return -1
	n,steps:=int(nv),int(sv);cells:=n*n
	if output==nil||capacity<c.size_t(cells) do return -2
	var a:[36]f64
	var staged:[36]f64
	for i:=0;i<n;i+=1 { for j:=0;j<n;j+=1 { a[i*n+j]=(f64(i)*f64(j+2)+2.0)/f64(n) } }
	for step:=0;step<steps;step+=1 { for i:=1;i<n-1;i+=1 { for j:=1;j<n-1;j+=1 {
		q:=i*n+j
		total:=a[q-n-1]+a[q-n]+a[q-n+1]+a[q-1]+a[q]+a[q+1]+a[q+n-1]+a[q+n]+a[q+n+1]
		a[q]=total/9.0
	} } }
	for q:=0;q<cells;q+=1 { staged[q]=a[q] }
	for q:=0;q<cells;q+=1 { output[q]=staged[q] }
	return i64(cells)
}
