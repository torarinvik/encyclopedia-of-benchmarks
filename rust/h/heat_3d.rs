// PolyBench/C heat-3d bounded port. See benchmarks/h/heat_3d/LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn polybench_heat_3d(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64 {
    if input.is_null()||length!=2{return -1;}
    let nv=*input;let sv=*input.add(1);
    if !nv.is_finite()||!sv.is_finite()||nv.fract()!=0.0||sv.fract()!=0.0||nv<1.0||nv>6.0||sv<0.0||sv>4.0{return -1;}
    let n=nv as usize;let steps=sv as usize;let cells=n*n*n;
    if output.is_null()||capacity<cells{return -2;}
    let mut a=[0.0f64;216];let mut b=[0.0f64;216];let mut staged=[0.0f64;216];
    for i in 0..n{for j in 0..n{for k in 0..n{let q=i*n*n+j*n+k;a[q]=((i+j+(n-k)) as f64)*10.0/n as f64;b[q]=a[q];}}}
    for _ in 0..steps{
        for i in 1..n.saturating_sub(1){for j in 1..n.saturating_sub(1){for k in 1..n.saturating_sub(1){let q=i*n*n+j*n+k;let c=a[q];b[q]=0.125*(a[q+n*n]-2.0*c+a[q-n*n])+0.125*(a[q+n]-2.0*c+a[q-n])+0.125*(a[q+1]-2.0*c+a[q-1])+c;}}}
        for i in 1..n.saturating_sub(1){for j in 1..n.saturating_sub(1){for k in 1..n.saturating_sub(1){let q=i*n*n+j*n+k;let c=b[q];a[q]=0.125*(b[q+n*n]-2.0*c+b[q-n*n])+0.125*(b[q+n]-2.0*c+b[q-n])+0.125*(b[q+1]-2.0*c+b[q-1])+c;}}}
    }
    staged[..cells].copy_from_slice(&a[..cells]);std::ptr::copy_nonoverlapping(staged.as_ptr(),output,cells);cells as i64
}
