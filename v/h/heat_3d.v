// PolyBench/C heat-3d bounded port. See benchmarks/h/heat_3d/LICENSE.txt.
import math

@[export: 'polybench_heat_3d']
pub fn polybench_heat_3d(input &f64,length usize,mut output &f64,capacity usize) i64 {
	unsafe {
		if input==nil||length!=2{return -1}
		nv:=input[0];sv:=input[1]
		if !nv.is_finite()||!sv.is_finite()||math.trunc(nv)!=nv||math.trunc(sv)!=sv||nv<1||nv>6||sv<0||sv>4{return -1}
		n,steps:=int(nv),int(sv);cells:=n*n*n
		if output==nil||capacity<usize(cells){return -2}
		mut a:=[216]f64{}
		mut b:=[216]f64{}
		mut staged:=[216]f64{}
		for i in 0..n { for j in 0..n { for k in 0..n {
			q:=i*n*n+j*n+k;a[q]=f64(i+j+(n-k))*10.0/f64(n);b[q]=a[q]
		} } }
		for _ in 0..steps {
			if n>2 {
				for i in 1..n-1 { for j in 1..n-1 { for k in 1..n-1 {
					q:=i*n*n+j*n+k;c0:=a[q]
					b[q]=0.125*(a[q+n*n]-2.0*c0+a[q-n*n])+0.125*(a[q+n]-2.0*c0+a[q-n])+0.125*(a[q+1]-2.0*c0+a[q-1])+c0
				} } }
				for i in 1..n-1 { for j in 1..n-1 { for k in 1..n-1 {
					q:=i*n*n+j*n+k;c0:=b[q]
					a[q]=0.125*(b[q+n*n]-2.0*c0+b[q-n*n])+0.125*(b[q+n]-2.0*c0+b[q-n])+0.125*(b[q+1]-2.0*c0+b[q-1])+c0
				} } }
			}
		}
		for q in 0..cells { staged[q]=a[q] }
		for q in 0..cells { output[q]=staged[q] }
		return i64(cells)
	}
}
