// Clean-room bounded iterative-compression feedback vertex set profile.
use core::ptr;
const N:usize=8;const INPUT:usize=59;
fn bits(mut x:u64)->u32{let mut n=0;while x!=0{n+=(x&1)as u32;x>>=1;}n}
fn root(p:&mut[usize;N],mut x:usize)->usize{while p[x]!=x{p[x]=p[p[x]];x=p[x];}x}
fn forest(g:&[[bool;N];N],n:usize,vertices:u64)->bool{let mut p=[0usize;N];for i in 0..n{p[i]=i;}for u in 0..n{if vertices>>u&1!=0{for v in u+1..n{if vertices>>v&1!=0&&g[u][v]{let a=root(&mut p,u);let b=root(&mut p,v);if a==b{return false;}p[a]=b;}}}}true}
fn compress(g:&[[bool;N];N],n:usize,prefix:u64,k:u32,current:u64)->Option<u64>{let mut x=current;loop{let cx=bits(x);let excluded=current&!x;if cx<=k&&forest(g,n,excluded){let eligible=prefix&!current;let mut s=eligible;loop{if bits(s)<=k-cx&&forest(g,n,prefix&!(x|s)){return Some(x|s);}if s==0{break;}s=(s-1)&eligible;}}if x==0{break;}x=(x-1)&current;}None}
fn solve_budget(g:&[[bool;N];N],n:usize,k:u32)->Option<u64>{let mut fvs=0u64;for i in 0..n{let prefix=(1u64<<(i+1))-1;let candidate=fvs|(1u64<<i);if bits(candidate)<=k{fvs=candidate;continue;}fvs=compress(g,n,prefix,k,candidate)?;}Some(fvs)}
fn put(out:*mut u8,at:usize,x:i64){let b=x as u64;for i in 0..8{unsafe{ptr::write(out.add(at+i),(b>>(8*i))as u8);}}}
#[no_mangle]
pub unsafe extern "C" fn undirected_feedback_vertex_set(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{if input.is_null()||length<3||length>INPUT{return -1;}let nn=*input;let mm=*input.add(1);let limit=*input.add(2);if nn<1||nn>8||mm<0||mm>28||limit<0||limit>4||length!=3+2*mm as usize{return -1;}let n=nn as usize;let mut g=[[false;N];N];let(mut pu,mut pv)=(-1i64,-1i64);for e in 0..mm as usize{let u=*input.add(3+2*e);let v=*input.add(4+2*e);if u<0||v<=u||v>=nn||u<pu||(u==pu&&v<=pv){return -1;}g[u as usize][v as usize]=true;g[v as usize][u as usize]=true;pu=u;pv=v;}if output.is_null()||capacity<16{return -2;}let mut found=false;let mut minimum=-1i64;for k in 0..=limit as u32{if solve_budget(&g,n,k).is_some(){found=true;minimum=k as i64;break;}}put(output,0,if found{1}else{0});put(output,8,minimum);16}
