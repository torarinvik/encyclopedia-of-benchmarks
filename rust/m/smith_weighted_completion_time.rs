const MAX_N:usize=12;const MAX_INPUT:usize=25;
unsafe fn put64(o:*mut u8,p:usize,x:i64){let b=x as u64;for j in 0..8{*o.add(p+j)=(b>>(8*j)) as u8;}}
#[no_mangle] pub unsafe extern "C" fn smith_weighted_completion_time(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3||length>MAX_INPUT{return -1}let n64=*input;if n64<1||n64>MAX_N as i64||length!=1+2*n64 as usize{return -1}
 let n=n64 as usize;let mut p=[0i64;MAX_N];let mut w=[0i64;MAX_N];let mut order=[0i64;MAX_N];
 for i in 0..n{p[i]=*input.add(1+2*i);w[i]=*input.add(2+2*i);if p[i]<1||p[i]>10000||w[i]<1||w[i]>10000{return -1}order[i]=i as i64;}
 let bytes=8*(n+1);if output.is_null()||capacity<bytes{return -2}
 for i in 1..n{let key=order[i];let mut j=i;while j>0{let prev=order[j-1] as usize;let k=key as usize;let before=w[k]*p[prev]>w[prev]*p[k]||(w[k]*p[prev]==w[prev]*p[k]&&k<prev);if !before{break}order[j]=order[j-1];j-=1}order[j]=key;}
 let mut elapsed=0i64;let mut total=0i64;for i in 0..n{let job=order[i] as usize;elapsed+=p[job];total+=w[job]*elapsed;}
 put64(output,0,total);for i in 0..n{put64(output,8*(i+1),order[i]);}bytes as i64
}
