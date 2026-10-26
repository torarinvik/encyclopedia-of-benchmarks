// Clean-room high-/low-degree vertex-cover reduction profile.
use core::ptr;
const N:usize=16;const M:usize=64;const INPUT:usize=131;const FIELDS:usize=133;
fn put(out:*mut u8,at:usize,x:i64){let bits=x as u64;for b in 0..8{unsafe{ptr::write(out.add(at+b),(bits>>(8*b))as u8);}}}
#[no_mangle]
pub unsafe extern "C" fn vertex_cover_kernelization(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3||length>INPUT{return -1;}let nn=*input;let mm=*input.add(1);let mut k=*input.add(2);
 if nn<1||nn>16||mm<0||mm>64||k<0||k>16||length!=3+2*mm as usize{return -1;}let n=nn as usize;let m=mm as usize;
 let mut edge=[[false;N];N];let(mut pu,mut pv)=(-1i64,-1i64);
 for e in 0..m{let u=*input.add(3+2*e);let v=*input.add(4+2*e);if u<0||v<=u||v>=nn||u<pu||(u==pu&&v<=pv){return -1;}edge[u as usize][v as usize]=true;edge[v as usize][u as usize]=true;pu=u;pv=v;}
 if output.is_null(){return -2;}let mut active=[false;N];for i in 0..n{active[i]=true;}let mut forced=0u64;let mut infeasible=false;
 loop{if k<0{infeasible=true;break;}let(mut chosen,mut neighbor,mut kind)=(n,n,0usize);
  for u in 0..n{if active[u]{let mut degree=0;for v in 0..n{if edge[u][v]{degree+=1;}}if degree==0{chosen=u;kind=1;break;}}}if kind==1{active[chosen]=false;continue;}
  for u in 0..n{if active[u]{let(mut degree,mut only)=(0,n);for v in 0..n{if edge[u][v]{degree+=1;only=v;}}if degree==1{chosen=u;neighbor=only;kind=2;break;}}}
  if kind==0{for u in 0..n{if active[u]{let mut degree=0;for v in 0..n{if edge[u][v]{degree+=1;}}if degree as i64>k{chosen=u;kind=3;break;}}}}
  if kind==0{break;}let f=if kind==2{neighbor}else{chosen};forced|=1u64<<f;active[f]=false;k-=1;for v in 0..n{edge[f][v]=false;edge[v][f]=false;}
 }
 let mut staged=[0i64;FIELDS];let mut count=0usize;staged[count]=if infeasible{0}else{1};count+=1;staged[count]=k;count+=1;staged[count]=forced as i64;count+=1;let mut active_mask=0u64;for v in 0..n{if active[v]{active_mask|=1u64<<v;}}staged[count]=active_mask as i64;count+=1;let mut rem=0usize;for u in 0..n{for v in u+1..n{if edge[u][v]{rem+=1;}}}staged[count]=rem as i64;count+=1;for u in 0..n{for v in u+1..n{if edge[u][v]{staged[count]=u as i64;staged[count+1]=v as i64;count+=2;}}}if capacity<8*count{return -2;}for i in 0..count{put(output,8*i,staged[i]);} (8*count) as i64
}
