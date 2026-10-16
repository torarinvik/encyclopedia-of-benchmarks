const MAX_N: usize = 32;
const MAX_Q: usize = 128;
fn find(parent: &mut [usize; MAX_N], mut x: usize) -> usize { while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x]; } x }
fn side(adj: &[u64;MAX_N], n:usize, start:usize, out:&mut [usize;MAX_N]) -> usize {
 let mut seen=[false;MAX_N];let mut stack=[0usize;MAX_N];let mut top=0;let mut count=0;stack[top]=start;top+=1;
 while top>0 {top-=1;let u=stack[top];if seen[u]{continue;}seen[u]=true;out[count]=u;count+=1;for v in 0..n{if (adj[u]>>v)&1!=0&&!seen[v]{stack[top]=v;top+=1;}}}count
}
#[no_mangle]
pub extern "C" fn decremental_connectivity(a:*const i64,len:usize)->i64 {
 if a.is_null()||len<3||len>3+2*(MAX_N-1)+3*MAX_Q{return -1;}let x=unsafe{std::slice::from_raw_parts(a,len)};let n0=x[0];let m0=x[1];if n0<1||n0>MAX_N as i64||m0<0||m0>=n0{return -1;}let n=n0 as usize;let m=m0 as usize;let ep=2+2*m;if len<=ep{return -1;}let q0=x[ep];if q0<0||q0>MAX_Q as i64||len!=ep+1+3*q0 as usize{return -1;}let q=q0 as usize;
 let mut adj=[0u64;MAX_N];let mut parent=[0usize;MAX_N];for i in 0..n{parent[i]=i;}
 for i in 0..m{let u0=x[2+2*i];let v0=x[3+2*i];if u0<0||u0>=n0||v0<0||v0>=n0||u0==v0{return -1;}let u=u0 as usize;let v=v0 as usize;if adj[u]>>v&1!=0{return -1;}let ru=find(&mut parent,u);let rv=find(&mut parent,v);if ru==rv{return -1;}parent[rv]=ru;adj[u]|=1u64<<v;adj[v]|=1u64<<u;}
 let mut comp=[usize::MAX;MAX_N];let mut next=0;for start in 0..n{if comp[start]!=usize::MAX{continue;}comp[start]=next;let mut stack=[0usize;MAX_N];let mut top=0;stack[top]=start;top+=1;while top>0{top-=1;let u=stack[top];for v in 0..n{if adj[u]>>v&1!=0&&comp[v]==usize::MAX{comp[v]=next;stack[top]=v;top+=1;}}}next+=1;}
 let mut h=14695981039346656037u64;for k in 0..q{let p=ep+1+3*k;let op=x[p];let u0=x[p+1];let v0=x[p+2];if (op!=0&&op!=1)||u0<0||u0>=n0||v0<0||v0>=n0{return -1;}let u=u0 as usize;let v=v0 as usize;if op==1{h^=(comp[u]==comp[v]) as u64;h=h.wrapping_mul(1099511628211);continue;}if adj[u]>>v&1==0||comp[u]!=comp[v]{return -1;}adj[u]&=!(1u64<<v);adj[v]&=!(1u64<<u);let mut left=[0usize;MAX_N];let mut right=[0usize;MAX_N];let lc=side(&adj,n,u,&mut left);let rc=side(&adj,n,v,&mut right);let (small,sc)=if lc<rc||(lc==rc&&u<v){(&left,lc)}else{(&right,rc)};for j in 0..sc{comp[small[j]]=next;}next+=1;}
 h as i64
}
