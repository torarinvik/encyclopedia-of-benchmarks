const MAX_N:usize=8;const MAX_M:usize=28;const MAX_INPUT:usize=59;
unsafe fn put(o:*mut u8,at:usize,x:i64){let b=x as u64;for i in 0..8{*o.add(at+i)=(b>>(8*i)) as u8;}}
fn connected(n:usize,m:usize,u:&[usize;MAX_M],v:&[usize;MAX_M],on:&[bool;MAX_M],skip:isize)->bool{let mut seen=[false;MAX_N];let mut q=[0usize;MAX_N];let mut h=0;let mut t=1;q[0]=0;seen[0]=true;while h<t{let a=q[h];h+=1;for e in 0..m{if !on[e]||e as isize==skip{continue}let b=if u[e]==a{v[e]}else if v[e]==a{u[e]}else{MAX_N};if b<MAX_N&&!seen[b]{seen[b]=true;q[t]=b;t+=1}}}seen[..n].iter().all(|x|*x)}
fn edge_connected(n:usize,m:usize,u:&[usize;MAX_M],v:&[usize;MAX_M],on:&[bool;MAX_M])->bool{if !connected(n,m,u,v,on,-1){return false}for e in 0..m{if on[e]&&!connected(n,m,u,v,on,e as isize){return false}}true}
#[no_mangle]
pub unsafe extern "C" fn two_edge_connected_spanning_subgraph_greedy(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>MAX_INPUT{return -1}let n0=*input;let m0=*input.add(1);if n0<3||n0>8||m0<3||m0>28||length!=2+2*m0 as usize{return -1}let n=n0 as usize;let m=m0 as usize;let mut u=[0usize;MAX_M];let mut v=[0usize;MAX_M];let mut on=[false;MAX_M];
 for i in 0..m{let a=*input.add(2+2*i);let b=*input.add(3+2*i);if a<0||a>=b||b>=n0{return -1}u[i]=a as usize;v[i]=b as usize;on[i]=true;for j in 0..i{if u[i]==u[j]&&v[i]==v[j]{return -1}}}
 if !edge_connected(n,m,&u,&v,&on){return -1}for e in 0..m{on[e]=false;if !edge_connected(n,m,&u,&v,&on){on[e]=true}}
 let count=on[..m].iter().filter(|x|**x).count();let bytes=8*(1+2*count);if output.is_null()||capacity<bytes{return -2}put(output,0,count as i64);let mut at=8;for a in 0..n{for b in a+1..n{for e in 0..m{if on[e]&&u[e]==a&&v[e]==b{put(output,at,a as i64);put(output,at+8,b as i64);at+=16}}}}bytes as i64
}
