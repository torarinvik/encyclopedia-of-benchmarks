const MAX_M:usize=8;const MAX_N:usize=32;const MAX_INPUT:usize=34;
unsafe fn put64(out:*mut u8,pos:usize,x:i64){let b=x as u64;for j in 0..8{*out.add(pos+j)=(b>>(8*j)) as u8;}}
#[no_mangle] pub unsafe extern "C" fn list_scheduling(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3||length>MAX_INPUT{return -1}let m64=*input;let n64=*input.add(1);
 if m64<1||m64>MAX_M as i64||n64<1||n64>MAX_N as i64||length!=2+n64 as usize{return -1}
 let m=m64 as usize;let n=n64 as usize;for i in 0..n{let x=*input.add(2+i);if x<1||x>10000{return -1}}
 let bytes=8*(1+n+m);if output.is_null()||capacity<bytes{return -2}
 let mut load=[0i64;MAX_M];let mut assign=[0i64;MAX_N];
 for i in 0..n{let mut best=0;for j in 1..m{if load[j]<load[best]{best=j}}assign[i]=best as i64;load[best]+=*input.add(2+i)}
 let mut span=load[0];for j in 1..m{if load[j]>span{span=load[j]}}
 put64(output,0,span);for i in 0..n{put64(output,8*(1+i),assign[i])}for j in 0..m{put64(output,8*(1+n+j),load[j])}bytes as i64
}
