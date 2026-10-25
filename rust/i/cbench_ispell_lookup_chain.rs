const M:usize=8;const E:usize=8;const W:usize=8;const Q:usize=8;
fn ihash(a:&[i64],modulus:usize)->usize{let mut h=0u32;let first=a.len().min(4);for &x in &a[..first]{h=(h<<8)|(x as u32-32)}for &x in &a[first..]{h=h.rotate_left(5)^(x as u32-32)}(h as usize)%modulus}
#[no_mangle]
pub unsafe extern "C" fn cbench_ispell_lookup_chain(input:*const i64,len:usize)->i64{
 if input.is_null()||len<3||len>108{return -1}let a=std::slice::from_raw_parts(input,len);
 if a[0]<1||a[0]>8||a[1]<1||a[1]>8||a[2]<0||a[2]>8{return -1}let m=a[0] as usize;let q=a[1] as usize;let n=a[2] as usize;
 if len<3+q+m+2*n{return -1}let h0=3+q;let nx0=h0+m;let l0=nx0+n;let mut p=l0+n;
 let query=&a[3..3+q];if query.iter().any(|x|*x<97||*x>122){return -1}
 let mut heads=[-1i64;M];let mut next=[-1i64;E];let mut lens=[0usize;E];let mut off=[0usize;E];
 for b in 0..m{heads[b]=a[h0+b];if heads[b]<-1||heads[b]>=n as i64{return -1}}
 for i in 0..n{next[i]=a[nx0+i];if next[i]<-1||next[i]>=n as i64||a[l0+i]<1||a[l0+i]>W as i64{return -1}lens[i]=a[l0+i] as usize;if p+lens[i]>len{return -1}off[i]=p;if a[p..p+lens[i]].iter().any(|x|*x<97||*x>122){return -1}p+=lens[i]}
 if p!=len{return -1}let mut seen=[false;E];let mut count=0;
 for b in 0..m{let mut x=heads[b];while x!=-1{let i=x as usize;if seen[i]{return -1}seen[i]=true;count+=1;if ihash(&a[off[i]..off[i]+lens[i]],m)!=b{return -1}x=next[i]}}
 if count!=n{return -1}let b=ihash(query,m);let mut x=heads[b];while x!=-1{let i=x as usize;if lens[i]==q&&a[off[i]..off[i]+q]==a[3..3+q]{return i as i64+1}x=next[i]}0
}
