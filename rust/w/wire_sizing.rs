const N:usize=6;const F:usize=7;
fn put(out:&mut[u8],at:usize,v:i64){out[at..at+8].copy_from_slice(&v.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn wire_sizing(v:*const i64,length:usize,out:*mut u8,capacity:usize)->i64{
 if v.is_null()||length<7||length>17{return -1}let n0=*v;if n0<1||n0>N as i64{return -1}let n=n0 as usize;let l=*v.add(1);let rd=*v.add(2);let cl=*v.add(3);let r0=*v.add(4);if l<1||l>1000||rd<1||rd>1000||cl<1||cl>1000||r0<1||r0>1000||length!=5+2*n{return -1}
 let mut h=[0i64;N];let mut c=[0i64;N];for i in 0..n{h[i]=*v.add(5+i);c[i]=*v.add(5+n+i);if h[i]<1||h[i]>32||c[i]<1||c[i]>1000||(i>0&&h[i]>=h[i-1])||(i>0&&c[i]>=c[i-1]){return -1}}
 let mut phi=[[0.0f64;N];N];let mut rho=[0.0f64;N];for i in 0..n{rho[i]=rd as f64*c[i]as f64+cl as f64*r0 as f64/h[i]as f64;for j in 0..n{let lo=i.min(j);let hi=i.max(j);phi[i][j]=r0 as f64*c[hi]as f64/h[lo]as f64;}}
 let mut best=f64::INFINITY;let mut best_l=[0.0f64;N];let mut found=false;for mask in 1u32..(1u32<<n){let mut ids=[0usize;N];let mut k=0;for i in 0..n{if mask&(1u32<<i)!=0{ids[k]=i;k+=1}}let mut a=[[0.0f64;N+2];N+1];for r in 0..k{for q in 0..k{a[r][q]=phi[ids[r]][ids[q]]}a[r][k]=1.0;a[r][k+1]=-rho[ids[r]]}for q in 0..k{a[k][q]=1.0}a[k][k+1]=l as f64;
  let mut ok=true;for col in 0..=k{let mut pivot=col;for r in col+1..=k{if a[r][col].abs()>a[pivot][col].abs(){pivot=r}}if a[pivot][col].abs()<1e-12{ok=false;break}if pivot!=col{a.swap(pivot,col)}let div=a[col][col];for q in col..=k+1{a[col][q]/=div}for r in 0..=k{if r!=col{let f=a[r][col];for q in col..=k+1{a[r][q]-=f*a[col][q]}}}}
  if !ok{continue}let mut x=[0.0f64;N];for r in 0..k{x[ids[r]]=a[r][k+1]}let lambda=a[k][k+1];let mut sum=0.0;for i in 0..n{if x[i] < -1e-8{ok=false}sum+=x[i];let mut g=rho[i]+lambda;for j in 0..n{g+=phi[i][j]*x[j]}if mask&(1u32<<i)==0&&g < -1e-7{ok=false}}if (sum-l as f64).abs()>1e-7{ok=false}if !ok{continue}
  let mut obj=(rd*cl)as f64;for i in 0..n{obj+=rho[i]*x[i];for j in 0..n{obj+=0.5*x[i]*phi[i][j]*x[j]}}if !found||obj<best-1e-7{found=true;best=obj;best_l=x}
 }
 if !found{return -1}let mut fields=[0i64;F];fields[0]=(best*1e6+0.5)as i64;for i in 0..n{fields[i+1]=((best_l[i].max(0.0))*1e6+0.5)as i64}let bytes=8*(n+1);if out.is_null()||capacity<bytes{return -2}let mut stage=[0u8;8*F];for i in 0..n+1{put(&mut stage,8*i,fields[i])}std::ptr::copy_nonoverlapping(stage.as_ptr(),out,bytes);bytes as i64
}
