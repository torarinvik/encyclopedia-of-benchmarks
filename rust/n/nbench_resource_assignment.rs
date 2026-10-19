const NMAX: usize = 8;
const CELLS: usize = NMAX*NMAX;
const MAX_ADJUST: usize = 2048;
fn first(a:&[i64;CELLS],mark:&mut [u8;CELLS],n:usize)->usize{
 for x in 0..n*n{mark[x]=0;}let mut total=0;
 loop{let mut made=0;
  for i in 0..n{let(mut count,mut selected)=(0,0);for j in 0..n{if a[i*n+j]==0&&mark[i*n+j]==0{count+=1;selected=j;}}if count==1{made+=1;total+=1;mark[i*n+selected]=1;for k in 0..n{if k!=i&&a[k*n+selected]==0{mark[k*n+selected]=2;}}}}
  for j in 0..n{let(mut count,mut selected)=(0,0);for i in 0..n{if a[i*n+j]==0&&mark[i*n+j]==0{count+=1;selected=i;}}if count==1{made+=1;total+=1;mark[selected*n+j]=1;for k in 0..n{if k!=j&&a[selected*n+k]==0{mark[selected*n+k]=2;}}}}
  if made==0{break;}
 }
 if total==n{return total;}for i in 0..n{let mut selected=n;for j in 0..n{if a[i*n+j]==0&&mark[i*n+j]==0{selected=j;break;}}if selected<n{mark[i*n+selected]=1;total+=1;for k in 0..n{if k!=selected&&a[i*n+k]==0{mark[i*n+k]=2;}}for k in 0..n{if k!=i&&a[k*n+selected]==0{mark[k*n+selected]=2;}}}}total
}
fn second(a:&mut [i64;CELLS],mark:&[u8;CELLS],n:usize)->bool{
 let mut rows=[0u8;NMAX];let mut cols=[0u8;NMAX];for i in 0..n{rows[i]=if(0..n).any(|j|mark[i*n+j]==1){0}else{1};}
 loop{let mut new_rows=0;for i in 0..n{if rows[i]==1{for j in 0..n{if a[i*n+j]==0{cols[j]=1;}}}}for j in 0..n{if cols[j]==1{for i in 0..n{if mark[i*n+j]==1&&rows[i]!=1{rows[i]=1;new_rows+=1;}}}}if new_rows==0{break;}}
 let mut smallest=i64::MAX;for i in 0..n{if rows[i]==1{for j in 0..n{if cols[j]==0&&a[i*n+j]<smallest{smallest=a[i*n+j];}}}}if smallest==i64::MAX{return false;}
 for i in 0..n{for j in 0..n{if rows[i]==1&&cols[j]==0{a[i*n+j]-=smallest;}else if rows[i]==0&&cols[j]==1{a[i*n+j]+=smallest;}}}true
}
#[no_mangle]
pub unsafe extern "C" fn nbench_resource_assignment(values:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if values.is_null()||length<2||length>1+CELLS+1{return -1;}let v=std::slice::from_raw_parts(values,length);let rn=v[0];if rn<1||rn>NMAX as i64{return -1;}let n=rn as usize;if length!=1+n*n{return -1;}
 let mut a=[0i64;CELLS];for i in 0..n*n{if v[i+1]<0||v[i+1]>1000{return -1;}a[i]=v[i+1];}
 for i in 0..n{let mut m=a[i*n];for j in 1..n{m=m.min(a[i*n+j]);}for j in 0..n{a[i*n+j]-=m;}}
 for j in 0..n{let mut m=a[j];for i in 1..n{m=m.min(a[i*n+j]);}if m!=0{for i in 0..n{a[i*n+j]-=m;}}}
 let mut mark=[0u8;CELLS];let mut done=false;for _ in 0..=MAX_ADJUST{if first(&a,&mut mark,n)==n{done=true;break;}if !second(&mut a,&mark,n){return -1;}}if !done{return -1;}
 let mut cols=[0i32;NMAX];let mut seen=[false;NMAX];for i in 0..n{let mut col=n;for j in 0..n{if mark[i*n+j]==1{if col!=n{return -1;}col=j;}}if col==n||seen[col]{return -1;}cols[i]=col as i32;seen[col]=true;}
 let bytes=n*4;if output.is_null()||capacity<bytes{return -2;}for i in 0..n{let x=cols[i] as u32;for b in 0..4{*output.add(4*i+b)=(x>>(8*b)) as u8;}}bytes as i64
}
