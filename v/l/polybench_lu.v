// PolyBench/C lu bounded port. See benchmarks/l/polybench_lu/LICENSE.txt.
import math

@[export: 'polybench_lu']
pub fn polybench_lu(input &f64,length usize,mut output &f64,capacity usize) i64 {
	unsafe {
		if input==nil||length!=1{return -1}
		nv:=input[0]
		if !nv.is_finite()||math.trunc(nv)!=nv||nv<1||nv>6{return -1}
		n:=int(nv);cells:=n*n
		if output==nil||capacity<usize(cells){return -2}
		mut a:=[36]f64{}
		mut base:=[36]f64{}
		mut staged:=[36]f64{}
		for i in 0..n { for j in 0..i { base[i*n+j]=1.0-f64(j)/f64(n) };base[i*n+i]=1.0 }
		for t in 0..n { for r in 0..n { for s in 0..n { a[r*n+s]+=base[r*n+t]*base[s*n+t] } } }
		for i in 0..n {
			for j in 0..i { for k in 0..j { a[i*n+j]-=a[i*n+k]*a[k*n+j] };a[i*n+j]/=a[j*n+j] }
			for j in i..n { for k in 0..i { a[i*n+j]-=a[i*n+k]*a[k*n+j] } }
		}
		for q in 0..cells { staged[q]=a[q] }
		for q in 0..cells { output[q]=staged[q] }
		return i64(cells)
	}
}
