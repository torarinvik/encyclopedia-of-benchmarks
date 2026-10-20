// Bounded beta=2 lune graph adapted from ParGeo; see benchmarks/b/beta_skeleton/LICENSE.txt.
use std::slice;
#[no_mangle]
pub unsafe extern "C" fn beta_skeleton(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<3||length>65{return -1;}let values=slice::from_raw_parts(input,length);let n0=values[0];if n0<1||n0>32||length!=1+2*n0 as usize{return -1;}let n=n0 as usize;
    let(mut x,mut y)=([0_i64;32],[0_i64;32]);for i in 0..n{x[i]=values[1+2*i];y[i]=values[2+2*i];if x[i]<-1000||x[i]>1000||y[i]<-1000||y[i]>1000{return -1;}for j in 0..i{if x[i]==x[j]&&y[i]==y[j]{return -1;}}}
    let mut edges=[0_u8;992];let mut count=0;
    for i in 0..n{for j in i+1..n{let dx=x[i]-x[j];let dy=y[i]-y[j];let d2=dx*dx+dy*dy;let mut blocked=false;
        for k in 0..n{if k==i||k==j{continue;}let aix=x[k]-x[i];let aiy=y[k]-y[i];let ajx=x[k]-x[j];let ajy=y[k]-y[j];if aix*aix+aiy*aiy<d2&&ajx*ajx+ajy*ajy<d2{blocked=true;break;}}
        if !blocked{edges[count]=i as u8;edges[count+1]=j as u8;count+=2;}
    }}
    if output.is_null()||capacity<count{return -2;}let out=slice::from_raw_parts_mut(output,capacity);out[..count].copy_from_slice(&edges[..count]);count as i64
}
