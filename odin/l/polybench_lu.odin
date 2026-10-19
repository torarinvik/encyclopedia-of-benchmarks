// PolyBench/C lu bounded port. See benchmarks/l/polybench_lu/LICENSE.txt.
package polybench_lu
import "core:c"
import "core:math"

@(export)
polybench_lu :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
	if input==nil||length!=1 do return -1
	nv:=input[0]
	if nv!=nv||math.trunc(nv)!=nv||nv<1||nv>6 do return -1
	n:=int(nv);cells:=n*n
	if output==nil||capacity<c.size_t(cells) do return -2
	var a:[36]f64
	var base:[36]f64
	var staged:[36]f64
	for i:=0;i<n;i+=1 { for j:=0;j<=i;j+=1 { base[i*n+j]=1.0-f64(j)/f64(n) };base[i*n+i]=1.0 }
	for t:=0;t<n;t+=1 { for r:=0;r<n;r+=1 { for s:=0;s<n;s+=1 { a[r*n+s]+=base[r*n+t]*base[s*n+t] } } }
	for i:=0;i<n;i+=1 {
		for j:=0;j<i;j+=1 { for k:=0;k<j;k+=1 { a[i*n+j]-=a[i*n+k]*a[k*n+j] };a[i*n+j]/=a[j*n+j] }
		for j:=i;j<n;j+=1 { for k:=0;k<i;k+=1 { a[i*n+j]-=a[i*n+k]*a[k*n+j] } }
	}
	for q:=0;q<cells;q+=1 { staged[q]=a[q] }
	for q:=0;q<cells;q+=1 { output[q]=staged[q] }
	return i64(cells)
}
