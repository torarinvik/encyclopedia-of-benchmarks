//! Clean-room sample-induced compressed quadtree split profile.
use std::slice;

unsafe fn put_i64_le(out: *mut u8, at: usize, value: i64) {
    for (i,b) in value.to_le_bytes().iter().enumerate() { out.add(at+i).write(*b); }
}

#[no_mangle]
pub unsafe extern "C" fn k_quadtree_sampled_point_subdivision(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(3..=68).contains(&length) { return -1; }
    let v=slice::from_raw_parts(input,length);let nv=v[0];let kv=v[1];let dv=v[2];
    if !(1..=32).contains(&nv)||kv<1||kv>nv||!(1..=8).contains(&dv){return -1;}
    let n=nv as usize;let k=kv as usize;let d=dv as usize;if length!=3+2*n{return -1;}
    let side=1_i64<<d;let mut keys=[0_u32;32];
    for i in 0..n{
        let x=v[3+2*i];let y=v[4+2*i];if x<0||y<0||x>=side||y>=side{return -1;}
        let mut key=0_u32;for bit in (0..d).rev(){key=(key<<2)|((((x as u32>>bit)&1)<<1)|((y as u32>>bit)&1));}keys[i]=key;
    }
    keys[..n].sort_unstable();if keys[..n].windows(2).any(|w|w[0]==w[1]){return -1;}
    let samples=(n-1)/k+1;let mut sd=[0_u8;31];let mut sp=[0_u32;31];let mut count=0;
    for i in 0..samples.saturating_sub(1){let a=keys[i*k];let b=keys[(i+1)*k];let mut common=0;
        while common<d{let shift=2*(d-common-1);if ((a>>shift)&3)!=((b>>shift)&3){break;}common+=1;}
        let prefix=if common==0{0}else{a>>(2*(d-common))};let mut j=0;while j<count&&(sd[j] as usize!=common||sp[j]!=prefix){j+=1;}
        if j==count{sd[count]=common as u8;sp[count]=prefix;count+=1;}
    }
    for i in 1..count{let depth=sd[i];let prefix=sp[i];let start=prefix<<(2*(d-depth as usize));let mut j=i;
        while j>0{let prev=sp[j-1]<<(2*(d-sd[j-1] as usize));if prev<start||(prev==start&&sd[j-1]<=depth){break;}sd[j]=sd[j-1];sp[j]=sp[j-1];j-=1;}
        sd[j]=depth;sp[j]=prefix;
    }
    let bytes=8*(1+2*count);if output.is_null()||capacity<bytes{return -2;}
    put_i64_le(output,0,count as i64);for i in 0..count{put_i64_le(output,8*(1+2*i),sd[i] as i64);put_i64_le(output,8*(2+2*i),sp[i] as i64);}bytes as i64
}
