// PolyBench/C correlation bounded port. See benchmarks/c/polybench_correlation/LICENSE.txt.
import math

@[export: 'polybench_correlation']
pub fn polybench_correlation(input &f64,length usize,mut output &f64,capacity usize) i64 {
	unsafe {
		if input==nil||length!=2{return -1}
		nv:=input[0];mv:=input[1]
		if !nv.is_finite()||!mv.is_finite()||math.trunc(nv)!=nv||math.trunc(mv)!=mv||nv<1||nv>6||mv<1||mv>6{return -1}
		n,m:=int(nv),int(mv);required:=m*m
		if output==nil||capacity<usize(required){return -2}
		mut data:=[36]f64{};mut corr:=[36]f64{};mut mean:=[6]f64{};mut stddev:=[6]f64{};mut staged:=[36]f64{}
		float_n:=f64(n)
		for i in 0..n { for j in 0..m { data[i*m+j]=f64(i*j)/f64(m)+f64(i) } }
		for j in 0..m { mean[j]=0;for i in 0..n { mean[j]+=data[i*m+j] };mean[j]/=float_n }
		for j in 0..m { stddev[j]=0;for i in 0..n { d:=data[i*m+j]-mean[j];stddev[j]+=d*d };stddev[j]/=float_n;stddev[j]=math.sqrt(stddev[j]);if stddev[j]<=0.1 { stddev[j]=1.0 } }
		root_n:=math.sqrt(float_n)
		for i in 0..n { for j in 0..m { data[i*m+j]-=mean[j];data[i*m+j]/=root_n*stddev[j] } }
		if m>1 { for i in 0..m-1 { corr[i*m+i]=1.0;for j in i+1..m { corr[i*m+j]=0;for k in 0..n { corr[i*m+j]+=data[k*m+i]*data[k*m+j] };corr[j*m+i]=corr[i*m+j] } } }
		corr[(m-1)*m+m-1]=1.0
		for q in 0..required { staged[q]=corr[q] }
		for q in 0..required { output[q]=staged[q] }
		return i64(required)
	}
}
