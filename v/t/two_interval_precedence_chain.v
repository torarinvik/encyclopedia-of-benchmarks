// Clean-room longest precedence chain of 2-intervals.
module two_interval_precedence_chain
const max_n=16
fn before(v &i64,a int,b int)bool{for q in 0..4{x:=v[1+4*a+q];y:=v[1+4*b+q];if x!=y{return x<y}};return a<b}
fn precedes(v &i64,a int,b int)bool{return v[1+4*a+1]<v[1+4*b]&&v[1+4*a+3]<v[1+4*b+2]}
fn lexless(a [max_n]int,an int,b [max_n]int,bn int)bool{limit:=if an<bn{an}else{bn};for i in 0..limit{if a[i]!=b[i]{return a[i]<b[i]}};return an<bn}
fn put(mut out &u8,at int,x i64){mut bits:=u64(x);for q in 0..8{unsafe{out[at+q]=u8(bits&255)};bits>>=8}}
@[export:'two_interval_precedence_chain']
pub fn two_interval_precedence_chain(v &i64,n usize,mut out &u8,cap usize)i64{unsafe{
 if v==nil||n<5||n>65||v[0]<1||v[0]>max_n{return -1};count:=int(v[0]);if n!=usize(1+4*count){return -1}
 for i in 0..count{p:=1+4*i;for q in 0..4{if v[p+q]<0||v[p+q]>63{return -1}};if v[p]>=v[p+1]||v[p+2]>=v[p+3]||v[p+1]>=v[p+2]{return -1}}
 mut order:=[max_n]int{};for i in 0..count{order[i]=i};for i in 1..count{value:=order[i];mut j:=i;for j>0&&before(v,value,order[j-1]){order[j]=order[j-1];j--};order[j]=value}
 mut paths:=[max_n][max_n]int{};mut lens:=[max_n]int{};for i in 0..count{paths[i][0]=order[i];lens[i]=1;for j in 0..i{if precedes(v,order[j],order[i]){mut candidate:=paths[j];candidate[lens[j]]=order[i];m:=lens[j]+1;if m>lens[i]||(m==lens[i]&&lexless(candidate,m,paths[i],lens[i])){paths[i]=candidate;lens[i]=m}}}}
 mut best:=0;for i in 1..count{if lens[i]>lens[best]||(lens[i]==lens[best]&&lexless(paths[i],lens[i],paths[best],lens[best])){best=i}};mut fields:=[17]i64{};fields[0]=i64(lens[best]);for i in 0..lens[best]{fields[i+1]=i64(paths[best][i])};bytes:=8*(lens[best]+1);if out==nil||cap<usize(bytes){return -2};for i in 0..lens[best]+1{put(mut out,8*i,fields[i])};return i64(bytes)
}}
