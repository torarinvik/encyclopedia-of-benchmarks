// Clean-room exhaustive solver for bounded weighted popular matchings.
package weighted_popular_matching
import "core:c"
const MAX_N :: 4
const MAX_FIELDS :: 6
decode :: proc "contextless"(code0,n,m:int,a:^[MAX_N]int)->bool{code:=code0;used:=0;for i:=0;i<n;i+=1{digit:=code%(m+1);code/=(m+1);a[i]=digit-1;if digit>0{bit:=1<<(digit-1);if (used&bit)!=0{return false};used|=bit}};return true}
lexless :: proc "contextless"(a,b:[MAX_N]int,n:int)->bool{for i:=0;i<n;i+=1{if a[i]!=b[i]{return a[i]<b[i]}};return false}
put :: proc "contextless"(out:[^]u8,at:int,x:i64){bits:=u64(x);for i:=0;i<8;i+=1{out[at+i]=u8(bits&255);bits>>=8}}
@(export)
weighted_popular_matching :: proc "c"(v:[^]i64,length:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||length<4||length>22||v[0]<1||v[0]>MAX_N||v[1]<1||v[1]>MAX_N do return -1;n,m:=int(v[0]),int(v[1]);if length!=c.size_t(2+n+n*m) do return -1
 for i:=0;i<n;i+=1{if v[2+i]<1||v[2+i]>1000 do return -1;seen:=0;for j:=0;j<m;j+=1{rank:=v[2+n+i*m+j];if rank<0||rank>=i64(m)||(seen&(1<<int(rank)))!=0 do return -1;seen|=1<<int(rank)}}
 total:=1;for i:=0;i<n;i+=1{total*=m+1};best_card:=-1;best:[MAX_N]int;for i:=0;i<MAX_N;i+=1{best[i]=-1}
 for code:=0;code<total;code+=1{candidate:[MAX_N]int;if !decode(code,n,m,&candidate){continue};popular:=true;for other_code:=0;other_code<total&&popular;other_code+=1{other:[MAX_N]int;if !decode(other_code,n,m,&other){continue};score:i64=0;for i:=0;i<n;i+=1{rc:=i64(m);ro:=i64(m);if candidate[i]>=0{rc=v[2+n+i*m+candidate[i]]};if other[i]>=0{ro=v[2+n+i*m+other[i]]};if ro<rc{score+=v[2+i]}else if ro>rc{score-=v[2+i]}};if score>0{popular=false}}
  if popular{card:=0;for i:=0;i<n;i+=1{if candidate[i]>=0{card+=1}};if card>best_card||(card==best_card&&lexless(candidate,best,n)){best_card=card;best=candidate}}
 }
 fields:[MAX_FIELDS]i64;fields[0]=0;if best_card>=0{fields[0]=1};fields[1]=i64(max(best_card,0));for i:=0;i<n;i+=1{fields[2+i]=-1;if best_card>=0{fields[2+i]=i64(best[i])}};bytes:=8*(n+2);if out==nil||cap<c.size_t(bytes) do return -2;for i:=0;i<n+2;i+=1{put(&out[0],8*i,fields[i])};return i64(bytes)
}
