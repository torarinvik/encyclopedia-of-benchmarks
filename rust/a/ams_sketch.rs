fn put(out:&mut [u8],x:i64){out[..8].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn ams_sketch(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<4||length>116{return -1;}let v=unsafe{core::slice::from_raw_parts(input,length)};
    let (d0,w0,k0,u0)=(v[0],v[1],v[2],v[3]);if ![1,3,5].contains(&d0)||!(1..=8).contains(&w0)||!(1..=8).contains(&k0)||!(0..=16).contains(&u0){return -1;}
    let (d,w,k,u)=(d0 as usize,w0 as usize,k0 as usize,u0 as usize);let start=4+2*d*k;if length!=start+2*u{return -1;}
    for r in 0..d{for key in 0..k{let p=4+2*(r*k+key);if v[p]<0||v[p]>=w as i64||(v[p+1]!=-1&&v[p+1]!=1){return -1;}}}
    for i in 0..u{let key=v[start+2*i];let weight=v[start+2*i+1];if key<0||key>=k as i64||!(-1000..=1000).contains(&weight){return -1;}}
    let mut counters=[[0i64;8];5];let mut estimates=[0i64;5];
    for i in 0..u{let key=v[start+2*i] as usize;let weight=v[start+2*i+1];for r in 0..d{let p=4+2*(r*k+key);let bucket=v[p] as usize;let sign=v[p+1];counters[r][bucket]+=weight*sign;}}
    for r in 0..d{for b in 0..w{estimates[r]+=counters[r][b]*counters[r][b];}}
    for i in 1..d{let x=estimates[i];let mut j=i;while j>0&&estimates[j-1]>x{estimates[j]=estimates[j-1];j-=1;}estimates[j]=x;}
    if capacity<8||output.is_null(){return -2;}let out=unsafe{core::slice::from_raw_parts_mut(output,8)};put(out,estimates[d/2]);8
}
