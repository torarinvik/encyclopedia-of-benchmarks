// PolyBench/C seidel-2d bounded port. See benchmarks/s/polybench_seidel_2d/LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn polybench_seidel_2d(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    if input.is_null()||length!=2{return -1;}let nv=*input;let sv=*input.add(1);
    if !nv.is_finite()||!sv.is_finite()||nv.fract()!=0.0||sv.fract()!=0.0||nv<1.0||nv>6.0||sv<0.0||sv>4.0{return -1;}
    let n=nv as usize;let steps=sv as usize;let cells=n*n;if output.is_null()||capacity<cells{return -2;}
    let mut a=[0.0f64;36];let mut staged=[0.0f64;36];
    for i in 0..n{for j in 0..n{a[i*n+j]=(i as f64*(j+2) as f64+2.0)/n as f64;}}
    for _ in 0..steps{for i in 1..n.saturating_sub(1){for j in 1..n.saturating_sub(1){let q=i*n+j;let sum=a[q-n-1]+a[q-n]+a[q-n+1]+a[q-1]+a[q]+a[q+1]+a[q+n-1]+a[q+n]+a[q+n+1];a[q]=sum/9.0;}}}
    staged[..cells].copy_from_slice(&a[..cells]);std::ptr::copy_nonoverlapping(staged.as_ptr(),output,cells);cells as i64
}
