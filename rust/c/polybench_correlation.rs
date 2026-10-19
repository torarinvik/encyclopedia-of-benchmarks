// PolyBench/C correlation bounded port. See benchmarks/c/polybench_correlation/LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn polybench_correlation(input:*const f64,length:usize,output:*mut f64,capacity:usize)->i64{
    if input.is_null()||length!=2{return -1;}let nv=*input;let mv=*input.add(1);
    if !nv.is_finite()||!mv.is_finite()||nv.fract()!=0.0||mv.fract()!=0.0||nv<1.0||nv>6.0||mv<1.0||mv>6.0{return -1;}
    let n=nv as usize;let m=mv as usize;let required=m*m;if output.is_null()||capacity<required{return -2;}
    let mut data=[0.0f64;36];let mut corr=[0.0f64;36];let mut mean=[0.0f64;6];let mut stddev=[0.0f64;6];let mut staged=[0.0f64;36];let float_n=n as f64;
    for i in 0..n{for j in 0..m{data[i*m+j]=(i*j) as f64/m as f64+i as f64;}}
    for j in 0..m{mean[j]=0.0;for i in 0..n{mean[j]+=data[i*m+j];}mean[j]/=float_n;}
    for j in 0..m{stddev[j]=0.0;for i in 0..n{let d=data[i*m+j]-mean[j];stddev[j]+=d*d;}stddev[j]/=float_n;stddev[j]=stddev[j].sqrt();if stddev[j]<=0.1{stddev[j]=1.0;}}
    let scale=float_n.sqrt();for i in 0..n{for j in 0..m{data[i*m+j]-=mean[j];data[i*m+j]/=scale*stddev[j];}}
    for i in 0..m.saturating_sub(1){corr[i*m+i]=1.0;for j in i+1..m{corr[i*m+j]=0.0;for k in 0..n{corr[i*m+j]+=data[k*m+i]*data[k*m+j];}corr[j*m+i]=corr[i*m+j];}}
    corr[(m-1)*m+m-1]=1.0;staged[..required].copy_from_slice(&corr[..required]);std::ptr::copy_nonoverlapping(staged.as_ptr(),output,required);required as i64
}
