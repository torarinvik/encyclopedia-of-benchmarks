module triangle_union_area_vertical_decomposition

struct Rat { n i64; d i64 }
struct Seg { x0 i64; y0 i64; x1 i64; y1 i64; id int }
struct Interval { lo Rat; hi Rat; low Seg; high Seg; li int; hiid int }
fn abs64(x i64) i64 { return if x < 0 { -x } else { x } }
fn gcd64(a0 i64,b0 i64) i64 { mut a:=abs64(a0);mut b:=abs64(b0);for b!=0{t:=a%b;a=b;b=t};return if a==0{1}else{a} }
fn rat(n0 i64,d0 i64) Rat { mut n:=n0;mut d:=d0;if d<0{n = -n;d = -d};g:=gcd64(n,d);return Rat{n/g,d/g} }
fn radd(a Rat,b Rat) Rat { return rat(a.n*b.d+b.n*a.d,a.d*b.d) }
fn rsub(a Rat,b Rat) Rat { return rat(a.n*b.d-b.n*a.d,a.d*b.d) }
fn rmul(a Rat,b Rat) Rat { return rat(a.n*b.n,a.d*b.d) }
fn rdiv(a Rat,b Rat) Rat { return rat(a.n*b.d,a.d*b.n) }
fn rcmp(a Rat,b Rat) int { x:=a.n*b.d;y:=b.n*a.d;return if x<y{-1}else if x>y{1}else{0} }
fn cross(ax i64,ay i64,bx i64,by i64) i64 { return ax*by-ay*bx }
fn orient(ax i64,ay i64,bx i64,by i64,cx i64,cy i64) i64 { return cross(bx-ax,by-ay,cx-ax,cy-ay) }
fn yat(s Seg,x Rat) Rat { return radd(rat(s.y0,1),rmul(rat(s.y1-s.y0,s.x1-s.x0),rsub(x,rat(s.x0,1)))) }
fn intersection(a Seg,b Seg) ?Rat { rx:=a.x1-a.x0;ry:=a.y1-a.y0;sx:=b.x1-b.x0;sy:=b.y1-b.y0;den:=cross(rx,ry,sx,sy);if den==0{return none};qx:=b.x0-a.x0;qy:=b.y0-a.y0;t:=rat(cross(qx,qy,sx,sy),den);u:=rat(cross(qx,qy,rx,ry),den);if rcmp(t,rat(0,1))<0||rcmp(t,rat(1,1))>0||rcmp(u,rat(0,1))<0||rcmp(u,rat(1,1))>0{return none};return radd(rat(a.x0,1),rmul(t,rat(rx,1))) }
fn push_event(mut events []Rat,x Rat) { for e in events{if rcmp(e,x)==0{return}};events << x }
fn integrate(mut area Rat,low Seg,high Seg,xl Rat,xr Rat) { h0:=rsub(yat(high,xl),yat(low,xl));h1:=rsub(yat(high,xr),yat(low,xr));area=radd(area,rmul(rsub(xr,xl),rdiv(radd(h0,h1),rat(2,1)))) }
fn less_interval(a Interval,b Interval) bool { c:=rcmp(a.lo,b.lo);if c!=0{return c<0};if a.li!=b.li{return a.li<b.li};h:=rcmp(a.hi,b.hi);if h!=0{return h<0};return a.hiid<b.hiid }

@[export: 'triangle_union_area_vertical_decomposition']
pub fn triangle_union_area_vertical_decomposition(input &i64,length usize,mut output &u8,capacity usize) i64 {
    if unsafe { input == nil } || length<1 || length>20{return -1};nval:=unsafe{input[0]};if nval<1||nval>3||length!=usize(1+6*nval){return -1};n:=int(nval)
    mut p:=[3][3][2]i64{}
    for t in 0..n{for j in 0..3{for k in 0..2{v:=unsafe{input[1+6*t+2*j+k]};if v < -1||v>1{return -1};p[t][j][k]=v}};if p[t][0]==p[t][1]||p[t][0]==p[t][2]||p[t][1]==p[t][2]||orient(p[t][0][0],p[t][0][1],p[t][1][0],p[t][1][1],p[t][2][0],p[t][2][1])==0{return -1}}
    mut segs:=[]Seg{};mut events:=[]Rat{}
    for t in 0..n{for j in 0..3{k:=(j+1)%3;a:=p[t][j];b:=p[t][k];segs << Seg{a[0],a[1],b[0],b[1],3*t+j};push_event(mut events,rat(a[0],1)}}
    for i in 0..segs.len{for j in i+1..segs.len{if x:=intersection(segs[i],segs[j]){push_event(mut events,x)}}}
    for i in 1..events.len{v:=events[i];mut j:=i;for j>0&&rcmp(v,events[j-1])<0{events[j]=events[j-1];j--};events[j]=v}
    mut area:=rat(0,1)
    for e in 0..events.len-1{xl:=events[e];xr:=events[e+1];if rcmp(xl,xr)>=0{continue};xm:=rdiv(radd(xl,xr),rat(2,1));mut iv:=[]Interval{}
        for t in 0..n{mut cr:=[]Seg{};mut ys:=[]Rat{};for j in 0..3{s:=segs[3*t+j];if s.x0!=s.x1&&rcmp(xm,rat(min(s.x0,s.x1),1))>0&&rcmp(xm,rat(max(s.x0,s.x1),1))<0{cr << s;ys << yat(s,xm)}};if cr.len==0{continue};if cr.len!=2{return -1};swap:=rcmp(ys[0],ys[1])>0||(rcmp(ys[0],ys[1])==0&&cr[0].id>cr[1].id);if swap{iv << Interval{ys[1],ys[0],cr[1],cr[0],cr[1].id,cr[0].id}}else{iv << Interval{ys[0],ys[1],cr[0],cr[1],cr[0].id,cr[1].id}}}
        for i in 1..iv.len{v:=iv[i];mut j:=i;for j>0&&less_interval(v,iv[j-1]){iv[j]=iv[j-1];j--};iv[j]=v}
        mut have:=false;mut low:=Seg{};mut high:=Seg{};mut top:=rat(0,1);mut high_id:=0
        for item in iv{if !have{low=item.low;high=item.high;top=item.hi;high_id=item.hiid;have=true;continue};if rcmp(item.lo,top)<=0{c:=rcmp(item.hi,top);if c>0||(c==0&&item.hiid<high_id){high=item.high;top=item.hi;high_id=item.hiid}}else{integrate(mut area,low,high,xl,xr);low=item.low;high=item.high;top=item.hi;high_id=item.hiid}}
        if have{integrate(mut area,low,high,xl,xr)}
    }
    if area.n<0||area.d<=0||area.n>11289600||area.d>2822400{return -1};if unsafe{output==nil}||capacity<16{return -2};for j in 0..8{unsafe{output[j]=u8(u64(area.n)>>(8*j));output[8+j]=u8(u64(area.d)>>(8*j))}};return 16
}
