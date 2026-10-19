// PolyBench/C seidel-2d bounded port. See benchmarks/s/polybench_seidel_2d/LICENSE.txt.
import math

@[export: 'polybench_seidel_2d']
pub fn polybench_seidel_2d(input &f64,length usize,mut output &f64,capacity usize) i64 {
	unsafe {
		if input==nil||length!=2{return -1}
		nv:=input[0];sv:=input[1]
		if !nv.is_finite()||!sv.is_finite()||math.trunc(nv)!=nv||math.trunc(sv)!=sv||nv<1||nv>6||sv<0||sv>4{return -1}
		n,steps:=int(nv),int(sv);cells:=n*n
		if output==nil||capacity<usize(cells){return -2}
		mut a:=[36]f64{};mut staged:=[36]f64{}
		for i in 0..n { for j in 0..n { a[i*n+j]=(f64(i)*f64(j+2)+2.0)/f64(n) } }
		for _ in 0..steps {
			if n>2 { for i in 1..n-1 { for j in 1..n-1 {
				q:=i*n+j
				total:=a[q-n-1]+a[q-n]+a[q-n+1]+a[q-1]+a[q]+a[q+1]+a[q+n-1]+a[q+n]+a[q+n+1]
				a[q]=total/9.0
			} } }
		}
		for q in 0..cells { staged[q]=a[q] }
		for q in 0..cells { output[q]=staged[q] }
		return i64(cells)
	}
}
