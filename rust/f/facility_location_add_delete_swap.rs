const MAX_TOTAL:usize=8;const MAX_M:usize=7;const MAX_INPUT:usize=75;
unsafe fn put(o:*mut u8,at:usize,x:i64){let b=x as u64;for i in 0..8{*o.add(at+i)=(b>>(8*i)) as u8;}}
fn lex_less(a:u32,b:u32,m:usize)->bool{let mut i=0;let mut j=0;loop{while i<m&&a&(1<<i)==0{i+=1}while j<m&&b&(1<<j)==0{j+=1}if i==m||j==m{return i==m&&j!=m}if i!=j{return i<j}i+=1;j+=1}}
fn objective(n:usize,m:usize,d:&[[i64;MAX_TOTAL];MAX_TOTAL],fee:&[i64;MAX_M],mask:u32)->i64{let mut x=0;for j in 0..m{if mask&(1<<j)!=0{x+=fee[j]}}for u in 0..n{let mut best=i64::MAX;for j in 0..m{if mask&(1<<j)!=0{best=best.min(d[u][n+j])}}x+=best}x}
fn consider(c:u32,n:usize,m:usize,d:&[[i64;MAX_TOTAL];MAX_TOTAL],fee:&[i64;MAX_M],best:&mut u32,best_cost:&mut i64){let v=objective(n,m,d,fee,c);if v<*best_cost||(v==*best_cost&&lex_less(c,*best,m)){*best=c;*best_cost=v;}}
#[no_mangle]
pub unsafe extern "C" fn facility_location_add_delete_swap(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<4||length>MAX_INPUT{return -1}let n0=*input;let m0=*input.add(1);if n0<1||m0<1||n0+m0>8||n0>7||m0>7{return -1}let n=n0 as usize;let m=m0 as usize;let q=n+m;if length!=2+q*q+m+1{return -1}
 let mut d=[[0i64;MAX_TOTAL];MAX_TOTAL];let mut fee=[0i64;MAX_M];let mut p=2;for i in 0..q{for j in 0..q{let v=*input.add(p);p+=1;if v<0||v>1000{return -1}d[i][j]=v}}
 for i in 0..q{if d[i][i]!=0{return -1}for j in 0..q{if i!=j&&d[i][j]<=0{return -1}if d[i][j]!=d[j][i]{return -1}for k in 0..q{if d[i][j]>d[i][k]+d[k][j]{return -1}}}}
 for j in 0..m{fee[j]=*input.add(p);p+=1;if fee[j]<0||fee[j]>1000{return -1}}let raw=*input.add(p);if raw<=0||raw as u64>=(1u64<<m){return -1}let mut current=raw as u32;let mut current_cost=objective(n,m,&d,&fee,current);
 for _ in 0..(1u32<<m){let mut best=current;let mut best_cost=current_cost;for j in 0..m{let bit=1u32<<j;if current&bit==0{consider(current|bit,n,m,&d,&fee,&mut best,&mut best_cost)}else if current&!bit!=0{consider(current&!bit,n,m,&d,&fee,&mut best,&mut best_cost);for k in 0..m{let other=1u32<<k;if current&other==0{consider((current&!bit)|other,n,m,&d,&fee,&mut best,&mut best_cost)}}}}if best_cost*10>=current_cost*9{break}current=best;current_cost=best_cost;}
 let count=current.count_ones() as usize;let out_bytes=8*(2+n+count);if output.is_null()||capacity<out_bytes{return -2}put(output,0,current_cost);put(output,8,count as i64);let mut at=16;for j in 0..m{if current&(1<<j)!=0{put(output,at,j as i64);at+=8}}for u in 0..n{let mut best=0;let mut dist=i64::MAX;for j in 0..m{if current&(1<<j)!=0&&d[u][n+j]<dist{dist=d[u][n+j];best=j}}put(output,at,best as i64);at+=8}at as i64
}
