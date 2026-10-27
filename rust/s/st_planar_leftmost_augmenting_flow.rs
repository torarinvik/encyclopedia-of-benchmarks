const N:usize=6;const M:usize=10;const MAX_INPUT:usize=60;
struct G{n:usize,m:usize,s:usize,t:usize,u:[usize;M],v:[usize;M],cap:[i64;M],deg:[usize;N],rot:[[usize;N];N]}
fn parse(a:&[i64])->Option<G>{
 if a.len()<4||a.len()>MAX_INPUT{return None}let n=a[0];let m=a[1];let s=a[2];let t=a[3];if n<2||n>N as i64||m<1||m>M as i64||s<0||s>=n||t<0||t>=n||s==t{return None}let (n,m,s,t)=(n as usize,m as usize,s as usize,t as usize);if a.len()<4+3*m{return None}
 let(mut u,mut v,mut cap)=([0usize;M],[0usize;M],[0i64;M]);let mut pairs=[[false;N];N];let mut pos=4;
 for e in 0..m{let x=a[pos];let y=a[pos+1];let c=a[pos+2];pos+=3;if x<0||x as usize>=n||y<0||y as usize>=n||x==y||c<0||c>5{return None}let(x,y)=(x as usize,y as usize);if pairs[x][y]||pairs[y][x]{return None}pairs[x][y]=true;pairs[y][x]=true;u[e]=x;v[e]=y;cap[e]=c;}
 let(mut deg,mut rot)=([0usize;N],[[0usize;N];N]);let mut occ=[[0u8;2];M];let mut seen=[[false;M];N];
 for x in 0..n{if pos>=a.len(){return None}let d=a[pos];pos+=1;if d<0||d>=n as i64||pos+d as usize>a.len(){return None}deg[x]=d as usize;for j in 0..deg[x]{let e=a[pos];pos+=1;if e<0||e as usize>=m{return None}let e=e as usize;if seen[x][e]{return None}seen[x][e]=true;rot[x][j]=e;if u[e]==x{occ[e][0]+=1}else if v[e]==x{occ[e][1]+=1}else{return None}}}
 if pos!=a.len()|| (0..m).any(|e|occ[e]!=[1,1]){return None}let mut vis=[false;N];let mut q=[0usize;N];let(mut head,mut tail)=(0,0);vis[s]=true;q[tail]=s;tail+=1;while head<tail{let x=q[head];head+=1;for e in 0..m{let y=if u[e]==x{Some(v[e])}else if v[e]==x{Some(u[e])}else{None};if let Some(y)=y{if !vis[y]{vis[y]=true;q[tail]=y;tail+=1}}}}if (0..n).any(|x|!vis[x]){return None}Some(G{n,m,s,t,u,v,cap,deg,rot})
}
fn rem(g:&G,f:&[i64;M],x:usize,e:usize)->i64{if g.u[e]==x{g.cap[e]-f[e]}else{f[e]}}
fn put(out:&mut [u8],value:i64){out[..8].copy_from_slice(&value.to_le_bytes())}
#[no_mangle]
pub unsafe extern "C" fn st_planar_leftmost_augmenting_flow(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<4||length>MAX_INPUT{return -1}let a=std::slice::from_raw_parts(input,length);let g=match parse(a){Some(x)=>x,None=>return -1};let mut f=[0i64;M];let mut total=0i64;
 loop{let(mut vis,mut par,mut pe,mut pd,mut next)=([false;N],[-1i32;N],[-1i32;N],[0i32;N],[0usize;N]);let mut stack=[0usize;N];let mut top=0;vis[g.s]=true;stack[top]=g.s;top+=1;
  while top>0&&!vis[g.t]{let x=stack[top-1];if next[x]>=g.deg[x]{top-=1;continue}let e=g.rot[x][next[x]];next[x]+=1;let y=if g.u[e]==x{g.v[e]}else{g.u[e]};if rem(&g,&f,x,e)>0&&!vis[y]{vis[y]=true;par[y]=x as i32;pe[y]=e as i32;pd[y]=if g.u[e]==x{1}else{-1};stack[top]=y;top+=1}}
  if !vis[g.t]{break}let mut d=i64::MAX;let mut y=g.t;while y!=g.s{let x=par[y] as usize;let e=pe[y] as usize;d=d.min(rem(&g,&f,x,e));y=x}y=g.t;while y!=g.s{let e=pe[y] as usize;f[e]+=i64::from(pd[y])*d;y=par[y] as usize}total+=d;
 }
 if output.is_null()||capacity<8{return -2}put(std::slice::from_raw_parts_mut(output,8),total);8
}
