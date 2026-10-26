// Clean-room Lexicographic Depth-First Search with 4-vertex certificates.
const N:usize=8;const FIELDS:usize=234;
fn put(out:&mut[u8;FIELDS*8],at:usize,x:i64){out[at..at+8].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn ldfs_ordering_certificate(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<3||n>10{return -1}let nn=*v;if !(1..=8).contains(&nn){return -1}let count=nn as usize;if n!=count+2{return -1}let start=*v.add(1);if start<0||start>=nn{return -1}let all=(1u64<<count)-1;let mut adj=[0u64;N];
 for i in 0..count{let x=*v.add(2+i);if x<0||x as u64>all||(x as u64&(1u64<<i))!=0{return -1}adj[i]=x as u64}for i in 0..count{for j in 0..count{if ((adj[i]>>j)&1)!=((adj[j]>>i)&1){return -1}}}
 let mut reached=1u64<<start;for _ in 0..count{let old=reached;for i in 0..count{if (reached>>i)&1!=0{reached|=adj[i]}}if old==reached{break}}if reached!=all{return -1}
 let mut order=[0usize;N];order[0]=start as usize;let mut used=1usize;let mut visited=1u64<<start;
 while used<count{let mut chosen=count;for x in 0..count{if (visited>>x)&1==0{let mut wins=chosen==count;if !wins{for k in (0..used).rev(){let u=order[k];let xb=(adj[x]>>u)&1;let cb=(adj[chosen]>>u)&1;if xb!=cb{wins=xb>cb;break}if k==0{wins=x<chosen}}}if wins{chosen=x}}}order[used]=chosen;used+=1;visited|=1u64<<chosen;}
 let mut fields=[0i64;FIELDS];fields[0]=count as i64;for i in 0..count{fields[1+i]=order[i] as i64}let mut certs=0usize;let mut at=count+2;
 for i in 0..count{for j in i+1..count{for k in j+1..count{let a=order[i];let b=order[j];let c=order[k];if (adj[a]>>c)&1!=0&&(adj[a]>>b)&1==0{let mut witness=-1i64;for t in i+1..j{let d=order[t];if (adj[d]>>b)&1!=0&&(adj[d]>>c)&1==0{witness=d as i64;break}}fields[at]=a as i64;fields[at+1]=b as i64;fields[at+2]=c as i64;fields[at+3]=witness;at+=4;certs+=1}}}}
 fields[count+1]=certs as i64;let bytes=at*8;if out.is_null()||cap<bytes{return -2}let mut staged=[0u8;FIELDS*8];for i in 0..at{put(&mut staged,8*i,fields[i])}std::ptr::copy_nonoverlapping(staged.as_ptr(),out,bytes);bytes as i64
}
