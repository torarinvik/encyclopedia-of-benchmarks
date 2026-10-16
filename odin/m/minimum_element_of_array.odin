package minimum_element_of_array
import "core:c"
next_rng :: proc(state:^u32)->u32{x:=state^;x^=x<<13;x^=x>>17;x^=x<<5;state^=if x==0{0x9e3779b9}else{x};return state^}
partition :: proc(a:^([128]i64),lo,hi:int)->int{pivot:=a^[hi];i:=lo;for j:=lo;j<hi;j+=1{if a^[j]<=pivot{a^[i],a^[j]=a^[j],a^[i];i+=1}};a^[i],a^[hi]=a^[hi],a^[i];return i}
select_k :: proc(a:^([128]i64),lo,hi,k:int,state:^u32)->i64{if lo==hi do return a^[lo];p:=lo+int(next_rng(state)%u32(hi-lo+1));a^[p],a^[hi]=a^[hi],a^[p];q:=partition(a,lo,hi);rank:=q-lo+1;if k==rank do return a^[q];if k<rank do return select_k(a,lo,q-1,k,state);return select_k(a,q+1,hi,k-rank,state)}
@(export)
minimum_element_of_array :: proc "c" (values:[^]i64,length:c.size_t)->i64{if values==nil||length<4 do return -1;n:=values[0];k:=values[1];seed:=values[2];if n<1||n>128||length!=c.size_t(n+3)||k<1||k>n||seed<0||seed>2147483647 do return -1;var a:[128]i64;for i:=0;i<int(n);i+=1{a[i]=values[i+3];if a[i]<-1_000_000||a[i]>1_000_000 do return -1;for j:=0;j<i;j+=1{if a[i]==a[j] do return -1}};state:=if seed==0{u32(0x9e3779b9)}else{u32(seed)};return select_k(&a,0,int(n)-1,int(k),&state)}
