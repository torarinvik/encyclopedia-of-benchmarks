// PolyBench/C correlation bounded port. See benchmarks/c/polybench_correlation/LICENSE.txt.
package polybench_correlation
import "core:c"
import "core:math"

@(export)
polybench_correlation :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
	if input==nil||length!=2 do return -1
	nv,mv:=input[0],input[1]
	if nv!=nv||mv!=mv||math.trunc(nv)!=nv||math.trunc(mv)!=mv||nv<1||nv>6||mv<1||mv>6 do return -1
	n,m:=int(nv),int(mv);required:=m*m
	if output==nil||capacity<c.size_t(required) do return -2
	var data:[36]f64;var corr:[36]f64;var mean:[6]f64;var stddev:[6]f64;var staged:[36]f64
	float_n:=f64(n)
	for i:=0;i<n;i+=1 { for j:=0;j<m;j+=1 { data[i*m+j]=f64(i*j)/f64(m)+f64(i) } }
	for j:=0;j<m;j+=1 { mean[j]=0;for i:=0;i<n;i+=1 { mean[j]+=data[i*m+j] };mean[j]/=float_n }
	for j:=0;j<m;j+=1 { stddev[j]=0;for i:=0;i<n;i+=1 { d:=data[i*m+j]-mean[j];stddev[j]+=d*d };stddev[j]/=float_n;stddev[j]=math.sqrt(stddev[j]);if stddev[j]<=0.1 { stddev[j]=1.0 } }
	root_n:=math.sqrt(float_n)
	for i:=0;i<n;i+=1 { for j:=0;j<m;j+=1 { data[i*m+j]-=mean[j];data[i*m+j]/=root_n*stddev[j] } }
	if m>1 { for i:=0;i<m-1;i+=1 { corr[i*m+i]=1.0;for j:=i+1;j<m;j+=1 { corr[i*m+j]=0;for k:=0;k<n;k+=1 { corr[i*m+j]+=data[k*m+i]*data[k*m+j] };corr[j*m+i]=corr[i*m+j] } } }
	corr[(m-1)*m+m-1]=1.0
	for q:=0;q<required;q+=1 { staged[q]=corr[q] }
	for q:=0;q<required;q+=1 { output[q]=staged[q] }
	return i64(required)
}
