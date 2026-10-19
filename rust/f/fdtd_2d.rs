// PolyBench/C fdtd-2d bounded port. See benchmarks/f/fdtd_2d/LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn fdtd_2d(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64 {
    if input.is_null()||length!=3{return -1;}
    let v=[*input,*input.add(1),*input.add(2)];
    if v.iter().any(|x|!x.is_finite()||x.fract()!=0.0)||v[0]<0.0||v[0]>4.0||v[1]<1.0||v[1]>6.0||v[2]<1.0||v[2]>6.0{return -1;}
    let (tmax,nx,ny)=(v[0] as usize,v[1] as usize,v[2] as usize);let n=nx*ny;let required=3*n;
    if output.is_null()||capacity<required{return -2;}
    let mut ex=[0.0f64;36];let mut ey=[0.0f64;36];let mut hz=[0.0f64;36];let mut fict=[0.0f64;4];let mut staged=[0.0f64;108];
    for t in 0..tmax{fict[t]=t as f64;}
    for i in 0..nx{for j in 0..ny{ex[i*ny+j]=(i*(j+1)) as f64/nx as f64;ey[i*ny+j]=(i*(j+2)) as f64/ny as f64;hz[i*ny+j]=(i*(j+3)) as f64/nx as f64;}}
    for t in 0..tmax{
        for j in 0..ny{ey[j]=fict[t];}
        for i in 1..nx{for j in 0..ny{ey[i*ny+j]=ey[i*ny+j]-0.5*(hz[i*ny+j]-hz[(i-1)*ny+j]);}}
        for i in 0..nx{for j in 1..ny{ex[i*ny+j]=ex[i*ny+j]-0.5*(hz[i*ny+j]-hz[i*ny+j-1]);}}
        for i in 0..nx.saturating_sub(1){for j in 0..ny.saturating_sub(1){hz[i*ny+j]=hz[i*ny+j]-0.7*((ex[i*ny+j+1]-ex[i*ny+j])+(ey[(i+1)*ny+j]-ey[i*ny+j]));}}
    }
    for i in 0..n{staged[i]=ex[i];staged[n+i]=ey[i];staged[2*n+i]=hz[i];}
    std::ptr::copy_nonoverlapping(staged.as_ptr(),output,required);required as i64
}
