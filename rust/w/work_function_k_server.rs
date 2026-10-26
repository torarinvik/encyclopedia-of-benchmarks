// Clean-room bounded work-function algorithm for finite k-server metrics.
use core::ptr;

const MAX_P: usize = 6; const MAX_K: usize = 3; const MAX_R: usize = 8; const MAX_CONFIGS: usize = 20; const MAX_INPUT: usize = 50;

fn store_i64_le(out:*mut u8,off:usize,value:i64){let b=value as u64;for j in 0..8{unsafe{ptr::write(out.add(off+j),(b>>(8*j))as u8);}}}
fn sort_cfg(x:&mut [i64;MAX_K],k:usize){for i in 0..k{for j in i+1..k{if x[j]<x[i]{x.swap(i,j);}}}}
fn find_cfg(cfg:&[[i64;MAX_K];MAX_CONFIGS],count:usize,x:&[i64;MAX_K],k:usize)->usize{for i in 0..count{if cfg[i][..k]==x[..k]{return i;}}count}
fn cfg_dist(a:&[i64;MAX_K],b:&[i64;MAX_K],k:usize,d:&[[i64;MAX_P];MAX_P])->i64{
 if k==1{return d[a[0]as usize][b[0]as usize];}
 if k==2{return (d[a[0]as usize][b[0]as usize]+d[a[1]as usize][b[1]as usize]).min(d[a[0]as usize][b[1]as usize]+d[a[1]as usize][b[0]as usize]);}
 let perms=[[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]];let mut best=i64::MAX;
 for q in perms{let v=d[a[0]as usize][b[q[0]]as usize]+d[a[1]as usize][b[q[1]]as usize]+d[a[2]as usize][b[q[2]]as usize];best=best.min(v);}best
}

#[no_mangle]
pub unsafe extern "C" fn work_function_k_server(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3||length>MAX_INPUT{return -1;}let p64=*input;let k64=*input.add(1);let n64=*input.add(2);
 if p64<2||p64>6||k64<1||k64>3||k64>p64||n64<0||n64>8{return -1;}
 let p=p64 as usize;let k=k64 as usize;let n=n64 as usize;let initial_at=3+p*p;let req_at=initial_at+k;if length!=req_at+n{return -1;}
 let mut d=[[0i64;MAX_P];MAX_P];for i in 0..p{for j in 0..p{let x=*input.add(3+i*p+j);if x<0||x>1000||(i==j&&x!=0)||(i!=j&&x==0){return -1;}d[i][j]=x;}}
 for i in 0..p{for j in 0..p{if d[i][j]!=d[j][i]{return -1;}for z in 0..p{if d[i][j]>d[i][z]+d[z][j]{return -1;}}}}
 let mut initial=[0i64;MAX_K];for i in 0..k{let x=*input.add(initial_at+i);if x<0||x>=p64{return -1;}for j in 0..i{if initial[j]==x{return -1;}}initial[i]=x;}sort_cfg(&mut initial,k);
 let mut requests=[0i64;MAX_R];for t in 0..n{requests[t]=*input.add(req_at+t);if requests[t]<0||requests[t]>=p64{return -1;}}
 let output_bytes=8*(2+n*k);if output.is_null()||capacity<output_bytes{return -2;}
 let mut cfg=[[0i64;MAX_K];MAX_CONFIGS];let mut count=0usize;
 for a in 0..p{if k==1{cfg[count][0]=a as i64;count+=1;continue;}for b in a+1..p{if k==2{cfg[count][0]=a as i64;cfg[count][1]=b as i64;count+=1;continue;}for c in b+1..p{cfg[count]=[a as i64,b as i64,c as i64];count+=1;}}}
 let mut work=[0i64;MAX_CONFIGS];let mut next=[0i64;MAX_CONFIGS];for x in 0..count{work[x]=cfg_dist(&initial,&cfg[x],k,&d);}
 let mut staged=[0i64;2+MAX_R*MAX_K];staged[0]=n as i64;staged[1]=k as i64;let mut current=initial;
 for t in 0..n{let r=requests[t];for x in 0..count{next[x]=i64::MAX;for y in 0..count{if !cfg[y][..k].contains(&r){continue;}let v=work[y]+cfg_dist(&cfg[y],&cfg[x],k,&d);next[x]=next[x].min(v);}}
  let mut best=i64::MAX;let mut best_slot=0usize;let mut chosen=current;let already=current[..k].contains(&r);if !already{for slot in 0..k{let mut cand=current; cand[slot]=r;sort_cfg(&mut cand,k);let idx=find_cfg(&cfg,count,&cand,k);let score=work[idx]+d[current[slot]as usize][r as usize];if score<best||(score==best&&slot<best_slot){best=score;best_slot=slot;chosen=cand;}}}
  for j in 0..k{staged[2+t*k+j]=chosen[j];current[j]=chosen[j];}for x in 0..count{work[x]=next[x];}
 }
 for i in 0..2+n*k{store_i64_le(output,8*i,staged[i]);}output_bytes as i64
}
