// Clean-room exact bounded minimum weighted connected dominating set.
package weighted_connected_dominating_set
import "core:c"
const MAX_N :: 16
put :: proc "contextless"(out:[^]u8,at:int,x:i64){bits:=u64(x);for i:=0;i<8;i+=1{out[at+i]=u8(bits&255);bits>>=8}}
@(export)
weighted_connected_dominating_set :: proc "c"(v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n<3||n>33||v[0]<1||v[0]>MAX_N do return -1;count:=int(v[0]);if n!=c.size_t(1+2*count) do return -1;all:=(u64(1)<<count)-1;adj:[MAX_N]u64
 for i:=0;i<count;i+=1{mask,weight:=v[1+i],v[1+count+i];if mask<0||u64(mask)>all||(u64(mask)&(u64(1)<<i))!=0||weight<1||weight>1000 do return -1;adj[i]=u64(mask)}
 for i:=0;i<count;i+=1{for j:=0;j<count;j+=1{if ((adj[i]>>j)&1)!=((adj[j]>>i)&1) do return -1}}
 best:i64=-1;best_mask:u64=0;mask:u64=1
 for mask<=all{dominated:=mask;cost:i64=0;for i:=0;i<count;i+=1{if ((mask>>i)&1)!=0{dominated|=adj[i];cost+=v[1+count+i]}};if dominated==all{seen:=mask&(~mask+1);for{old:=seen;for i:=0;i<count;i+=1{if ((seen>>i)&1)!=0{seen|=adj[i]&mask}};if old==seen{break}};if seen==mask&&(best<0||cost<best||(cost==best&&mask<best_mask)){best=cost;best_mask=mask}};mask+=1}
 if out==nil||cap<16 do return -2;put(&out[0],0,best);put(&out[0],8,i64(best_mask));return 16
}
