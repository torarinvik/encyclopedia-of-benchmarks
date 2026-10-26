// Clean-room longest precedence chain of 2-intervals.
package two_interval_precedence_chain
import "core:c"
const MAX_N :: 16
before :: proc "contextless" (v:[^]i64,a,b:int)->bool{for q:=0;q<4;q+=1{x,y:=v[1+4*a+q],v[1+4*b+q];if x!=y{return x<y}};return a<b}
precedes :: proc "contextless" (v:[^]i64,a,b:int)->bool{return v[1+4*a+1]<v[1+4*b]&&v[1+4*a+3]<v[1+4*b+2]}
lexless :: proc "contextless" (a:[MAX_N]int,an:int,b:[MAX_N]int,bn:int)->bool{limit:=min(an,bn);for i:=0;i<limit;i+=1{if a[i]!=b[i]{return a[i]<b[i]}};return an<bn}
@(export)
two_interval_precedence_chain :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n<5||n>65||v[0]<1||v[0]>MAX_N do return -1;count:=int(v[0]);if n!=c.size_t(1+4*count) do return -1
 for i:=0;i<count;i+=1{p:=1+4*i;for q:=0;q<4;q+=1{if v[p+q]<0||v[p+q]>63 do return -1};if v[p]>=v[p+1]||v[p+2]>=v[p+3]||v[p+1]>=v[p+2] do return -1}
 order:[MAX_N]int;for i:=0;i<count;i+=1{order[i]=i};for i:=1;i<count;i+=1{value:=order[i];j:=i;for j>0&&before(v,value,order[j-1]){order[j]=order[j-1];j-=1};order[j]=value}
 paths:[MAX_N][MAX_N]int;lens:[MAX_N]int;for i:=0;i<count;i+=1{paths[i][0]=order[i];lens[i]=1;for j:=0;j<i;j+=1{if precedes(v,order[j],order[i]){candidate:=paths[j];candidate[lens[j]]=order[i];m:=lens[j]+1;if m>lens[i]||(m==lens[i]&&lexless(candidate,m,paths[i],lens[i])){paths[i]=candidate;lens[i]=m}}}}
 best:=0;for i:=1;i<count;i+=1{if lens[i]>lens[best]||(lens[i]==lens[best]&&lexless(paths[i],lens[i],paths[best],lens[best])){best=i}};fields:[17]i64;fields[0]=i64(lens[best]);for i:=0;i<lens[best];i+=1{fields[i+1]=i64(paths[best][i])};bytes:=8*(lens[best]+1);if out==nil||cap<c.size_t(bytes) do return -2;for i:=0;i<lens[best]+1;i+=1{bits:=u64(fields[i]);for b:=0;b<8;b+=1{out[8*i+b]=u8(bits&255);bits>>=8}};return i64(bytes)
}
