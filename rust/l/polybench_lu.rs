// PolyBench/C lu bounded port. See benchmarks/l/polybench_lu/LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn polybench_lu(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    if input.is_null()||length!=1{return -1;}let nv=*input;
    if !nv.is_finite()||nv.fract()!=0.0||nv<1.0||nv>6.0{return -1;}
    let n=nv as usize;let cells=n*n;if output.is_null()||capacity<cells{return -2;}
    let mut a=[0.0f64;36];let mut base=[0.0f64;36];let mut staged=[0.0f64;36];
    for i in 0..n{for j in 0..=i{base[i*n+j]=1.0-j as f64/n as f64;}base[i*n+i]=1.0;}
    for t in 0..n{for r in 0..n{for s in 0..n{a[r*n+s]+=base[r*n+t]*base[s*n+t];}}}
    for i in 0..n{
        for j in 0..i{for k in 0..j{a[i*n+j]-=a[i*n+k]*a[k*n+j];}a[i*n+j]/=a[j*n+j];}
        for j in i..n{for k in 0..i{a[i*n+j]-=a[i*n+k]*a[k*n+j];}}
    }
    staged[..cells].copy_from_slice(&a[..cells]);std::ptr::copy_nonoverlapping(staged.as_ptr(),output,cells);cells as i64
}
