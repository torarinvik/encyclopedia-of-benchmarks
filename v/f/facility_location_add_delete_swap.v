module facility_location_add_delete_swap
import core.c
const max_total=8
const max_m=7
const max_input=75

fn put(out &u8,at int,x i64){bits:=u64(x);for i in 0..8{out[at+i]=u8((bits>>(8*i))&255)}}
fn lex_less(a,b u32,m int) bool {mut i:=0;mut j:=0;for{for i<m&&(a&(u32(1)<<i))==0{i++};for j<m&&(b&(u32(1)<<j))==0{j++};if i==m||j==m{return i==m&&j!=m};if i!=j{return i<j};i++;j++}}
fn objective(n,m int,d [][]i64,fee []i64,mask u32)i64{mut x:=i64(0);for j in 0..m{if mask&(u32(1)<<j)!=0{x+=fee[j]}};for u in 0..n{mut best:=i64(9223372036854775807);for j in 0..m{if mask&(u32(1)<<j)!=0&&d[u][n+j]<best{best=d[u][n+j]}};x+=best};return x}
fn consider(cand u32,n,m int,d [][]i64,fee []i64,mut best u32,mut best_cost i64){v:=objective(n,m,d,fee,cand);if v<best_cost||(v==best_cost&&lex_less(cand,best,m)){best=cand;best_cost=v}}

@[export: 'facility_location_add_delete_swap']
pub fn facility_location_add_delete_swap(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<4||length>max_input{return -1}
  n0,m0:=input[0],input[1];if n0<1||m0<1||n0+m0>8||n0>7||m0>7{return -1}
  n,m:=int(n0),int(m0);q:=n+m;if length!=usize(2+q*q+m+1){return -1}
  mut d:=[][]i64{len:q,init:[]i64{len:q,init:0}};mut fee:=[]i64{len:m,init:0};mut p:=2
  for i in 0..q{for j in 0..q{v:=input[p];p++;if v<0||v>1000{return -1};d[i][j]=v}}
  for i in 0..q{if d[i][i]!=0{return -1};for j in 0..q{if i!=j&&d[i][j]<=0{return -1};if d[i][j]!=d[j][i]{return -1};for k in 0..q{if d[i][j]>d[i][k]+d[k][j]{return -1}}}}
  for j in 0..m{fee[j]=input[p];p++;if fee[j]<0||fee[j]>1000{return -1}}
  raw:=input[p];if raw<=0||u64(raw)>=(u64(1)<<m){return -1}
  mut current:=u32(raw)
  mut current_cost:=objective(n,m,d,fee,current)
  for _ in 0..(1<<m){mut best:=current;mut best_cost:=current_cost;for j in 0..m{bit:=u32(1)<<j;if current&bit==0{consider(current|bit,n,m,d,fee,mut best,mut best_cost)}else if current&~bit!=0{consider(current&~bit,n,m,d,fee,mut best,mut best_cost);for k in 0..m{other:=u32(1)<<k;if current&other==0{consider((current&~bit)|other,n,m,d,fee,mut best,mut best_cost)}}}};if best_cost*10>=current_cost*9{break};current=best;current_cost=best_cost}
  mut count:=0;for j in 0..m{if current&(u32(1)<<j)!=0{count++}};out_bytes:=8*(2+n+count);if output==nil||capacity<usize(out_bytes){return -2};put(output,0,current_cost);put(output,8,i64(count));mut at:=16
  for j in 0..m{if current&(u32(1)<<j)!=0{put(output,at,i64(j));at+=8}}
  for u in 0..n{mut best:=0;mut dist:=i64(9223372036854775807);for j in 0..m{if current&(u32(1)<<j)!=0&&d[u][n+j]<dist{dist=d[u][n+j];best=j}};put(output,at,i64(best));at+=8}
  return i64(at)
 }
}
