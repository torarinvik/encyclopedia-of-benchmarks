// Clean-room exhaustive solver for bounded weighted popular matchings.
module weighted_popular_matching
const max_n=4;const max_fields=6
fn decode(mut code int,n int,m int,mut a [max_n]int)bool{mut used:=0;for i in 0..n{digit:=code%(m+1);code/=(m+1);a[i]=digit-1;if digit>0{bit:=1<<(digit-1);if (used&bit)!=0{return false};used|=bit}};return true}
fn lexless(a [max_n]int,b [max_n]int,n int)bool{for i in 0..n{if a[i]!=b[i]{return a[i]<b[i]}};return false}
fn put(mut out &u8,at int,x i64){mut bits:=u64(x);for i in 0..8{unsafe{out[at+i]=u8(bits&255)};bits>>=8}}
@[export:'weighted_popular_matching']
pub fn weighted_popular_matching(v &i64,n usize,mut out &u8,cap usize)i64{unsafe{
 if v==nil||n<4||n>22||v[0]<1||v[0]>max_n||v[1]<1||v[1]>max_n{return -1};rows,cols:=int(v[0]),int(v[1]);if n!=usize(2+rows+rows*cols){return -1}
 for i in 0..rows{if v[2+i]<1||v[2+i]>1000{return -1};mut seen:=0;for j in 0..cols{rank:=v[2+rows+i*cols+j];if rank<0||rank>=i64(cols)||(seen&(1<<int(rank)))!=0{return -1};seen|=1<<int(rank)}}
 mut total:=1;for _ in 0..rows{total*=cols+1};mut best_card:=-1;mut best:=[max_n]int{};for i in 0..max_n{best[i]=-1}
 for code in 0..total{mut candidate:=[max_n]int{};if !decode(code,rows,cols,mut candidate){continue};mut popular:=true
  for other_code in 0..total{if !popular{break};mut other:=[max_n]int{};if !decode(other_code,rows,cols,mut other){continue};mut score:=i64(0);for i in 0..rows{rc:=if candidate[i]<0{i64(cols)}else{v[2+rows+i*cols+candidate[i]]};ro:=if other[i]<0{i64(cols)}else{v[2+rows+i*cols+other[i]]};if ro<rc{score+=v[2+i]}else if ro>rc{score-=v[2+i]}};if score>0{popular=false}}
  if popular{mut card:=0;for i in 0..rows{if candidate[i]>=0{card++}};if card>best_card||(card==best_card&&lexless(candidate,best,rows)){best_card=card;best=candidate}}
 };mut fields:=[max_fields]i64{};fields[0]=if best_card<0{i64(0)}else{i64(1)};fields[1]=i64(if best_card<0{0}else{best_card});for i in 0..rows{fields[2+i]=if best_card<0{i64(-1)}else{i64(best[i])};};bytes:=8*(rows+2);if out==nil||cap<usize(bytes){return -2};for i in 0..rows+2{put(mut out,8*i,fields[i])};return i64(bytes)
}}
