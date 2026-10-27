package facility_location_add_delete_swap
import "core:c"
MAX_TOTAL :: 8
MAX_M :: 7
MAX_INPUT :: 75

put :: proc(o:[^]u8,at:int,x:i64){b:=u64(x);for i:=0;i<8;i+=1{o[at+i]=u8(b&255);b>>=8}}
lex_less :: proc(a,b:u32,m:int)->bool{i,j:=0,0;for{for i<m&&(a&(u32(1)<<i))==0{i+=1};for j<m&&(b&(u32(1)<<j))==0{j+=1};if i==m||j==m{return i==m&&j!=m};if i!=j{return i<j};i+=1;j+=1}}
objective :: proc(n,m:int,d:^([MAX_TOTAL][MAX_TOTAL]i64),fee:^([MAX_M]i64),mask:u32)->i64{x:i64=0;for j:=0;j<m;j+=1{if mask&(u32(1)<<j)!=0{x+=fee[j]}};for u:=0;u<n;u+=1{best:=i64(9223372036854775807);for j:=0;j<m;j+=1{if mask&(u32(1)<<j)!=0&&d[u][n+j]<best{best=d[u][n+j]}};x+=best};return x}
consider :: proc(cand:u32,n,m:int,d:^([MAX_TOTAL][MAX_TOTAL]i64),fee:^([MAX_M]i64),best:^u32,best_cost:^i64){v:=objective(n,m,d,fee,cand);if v<best_cost^||(v==best_cost^&&lex_less(cand,best^,m)){best^=cand;best_cost^=v}}

@(export)
facility_location_add_delete_swap :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<4||length>MAX_INPUT do return -1
 n0,m0:=input[0],input[1];if n0<1||m0<1||n0+m0>8||n0>7||m0>7 do return -1
 n,m:=int(n0),int(m0);q:=n+m;if length!=c.size_t(2+q*q+m+1) do return -1
 d:[MAX_TOTAL][MAX_TOTAL]i64;fee:[MAX_M]i64;p:=2
 for i:=0;i<q;i+=1{for j:=0;j<q;j+=1{v:=input[p];p+=1;if v<0||v>1000 do return -1;d[i][j]=v}}
 for i:=0;i<q;i+=1{if d[i][i]!=0 do return -1;for j:=0;j<q;j+=1{if i!=j&&d[i][j]<=0 do return -1;if d[i][j]!=d[j][i] do return -1;for k:=0;k<q;k+=1{if d[i][j]>d[i][k]+d[k][j] do return -1}}}}
 for j:=0;j<m;j+=1{fee[j]=input[p];p+=1;if fee[j]<0||fee[j]>1000 do return -1}
 raw:=input[p];if raw<=0||u64(raw)>=(u64(1)<<m) do return -1
 current:=u32(raw)
 current_cost:=objective(n,m,&d,&fee,current)
 for pass:=0;pass<(1<<m);pass+=1{best:=current;best_cost:=current_cost;for j:=0;j<m;j+=1{bit:=u32(1)<<j;if current&bit==0{consider(current|bit,n,m,&d,&fee,&best,&best_cost)}else if current&~bit!=0{consider(current&~bit,n,m,&d,&fee,&best,&best_cost);for k:=0;k<m;k+=1{other:=u32(1)<<k;if current&other==0{consider((current&~bit)|other,n,m,&d,&fee,&best,&best_cost)}}}};if best_cost*10>=current_cost*9{break};current=best;current_cost=best_cost}
 count:=0;for j:=0;j<m;j+=1{if current&(u32(1)<<j)!=0{count+=1}};out_bytes:=8*(2+n+count);if output==nil||capacity<c.size_t(out_bytes) do return -2;put(output,0,current_cost);put(output,8,i64(count));at:=16
 for j:=0;j<m;j+=1{if current&(u32(1)<<j)!=0{put(output,at,i64(j));at+=8}}
 for u:=0;u<n;u+=1{best:=0;dist:=i64(9223372036854775807);for j:=0;j<m;j+=1{if current&(u32(1)<<j)!=0&&d[u][n+j]<dist{dist=d[u][n+j];best=j}};put(output,at,i64(best));at+=8}
 return i64(at)
}
