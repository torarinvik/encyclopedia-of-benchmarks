// Clean-room exact branch-and-search vertex-cover profile.
use core::ptr;
const N:usize=16;const INPUT:usize=131;
fn bits(mut x:u64)->u32{let mut n=0;while x!=0{n+=(x&1)as u32;x>>=1;}n}
fn search(adj:&[[bool;N];N],n:usize,active:u64)->u64{
 let mut chosen=n;let mut best=0;let mut any=false;
 for u in 0..n{if active>>u&1!=0{let mut d=0;for v in 0..n{if active>>v&1!=0&&adj[u][v]{d+=1;}}if d>0{any=true;if chosen==n||d>best{chosen=u;best=d;}}}}
 if !any{return 0;}let bit=1u64<<chosen;let first=bit|search(adj,n,active&!bit);let mut neighbors=0u64;for v in 0..n{if active>>v&1!=0&&adj[chosen][v]{neighbors|=1u64<<v;}}let second=neighbors|search(adj,n,active&!(neighbors|bit));let a=bits(first);let b=bits(second);if a<b{first}else if b<a{second}else{first.min(second)}
}
fn put(out:*mut u8,at:usize,x:i64){let b=x as u64;for q in 0..8{unsafe{ptr::write(out.add(at+q),(b>>(8*q))as u8);}}}
#[no_mangle]
pub unsafe extern "C" fn vertex_cover_search_trees(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3||length>INPUT{return -1;}let nn=*input;let mm=*input.add(1);let k=*input.add(2);if nn<1||nn>16||mm<0||mm>64||k<0||k>nn||length!=3+2*mm as usize{return -1;}
 let n=nn as usize;let mut adj=[[false;N];N];let(mut pu,mut pv)=(-1i64,-1i64);for e in 0..mm as usize{let u=*input.add(3+2*e);let v=*input.add(4+2*e);if u<0||v<=u||v>=nn||u<pu||(u==pu&&v<=pv){return -1;}adj[u as usize][v as usize]=true;adj[v as usize][u as usize]=true;pu=u;pv=v;}
 if output.is_null()||capacity<24{return -2;}let cover=search(&adj,n,(1u64<<n)-1);let count=bits(cover)as i64;put(output,0,if count<=k{1}else{0});put(output,8,count);put(output,16,cover as i64);24
}
