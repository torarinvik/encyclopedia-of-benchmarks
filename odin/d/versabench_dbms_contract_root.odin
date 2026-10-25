package versabench_dbms_contract_root
import "core:c"
put :: proc "contextless" (o:[^]u8,w:int,x:i64){u:=u64(x);for b:=0;b<8;b+=1{o[w*8+b]=u8((u>>u64(8*b))&255)}}
@(export,link_name="versabench_dbms_contract_root")
versabench_dbms_contract_root :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n<3||n>12 do return -1;nv:=v[0];if nv<1||nv>5||n!=c.size_t(1+2*nv) do return -1;count:=int(nv);levels:[5]i64;entries:[5]i64
 for i:=0;i<count;i+=1{levels[i]=v[1+2*i];entries[i]=v[2+2*i];if levels[i]<0||levels[i]>4||entries[i]<0||entries[i]>4 do return -1;if i+1<count&&(levels[i]==0||entries[i]!=1||levels[i+1]!=levels[i]-1) do return -1}
 if levels[count-1]>0&&entries[count-1]==1 do return -1;if levels[count-1]>0&&entries[count-1]==0&&count!=1 do return -1;root:=0;promotions:=0;for levels[root]>0&&entries[root]==1{root+=1;promotions+=1};fl:=levels[root];fc:=entries[root];if fl>0&&fc==0{fl=0;fc=0};if out==nil||cap<24 do return -2;put(out,0,i64(promotions));put(out,1,fl);put(out,2,fc);return 24
}
