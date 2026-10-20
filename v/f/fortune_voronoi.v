module fortune_voronoi
import math

const nmax=8
const amax=15
const vmax=32
const omax=1024
const eps=1e-10
struct Pt{x f64;y f64}
struct Arc{site int;prev int;next int;active bool}
struct Circle{y f64;x f64;arc int;left int;right int}
struct Rat{n i64;d i64}
struct RPt{x Rat;y Rat}
fn rat(n0 i64,d0 i64)Rat{mut n:=n0;mut d:=d0;if d<0{n= -n;d= -d};mut a:=i64(math.abs(n));mut b:=i64(math.abs(d));for b!=0{t:=a%b;a=b;b=t};g:=if a==0{i64(1)}else{a};return Rat{n/g,d/g}}
fn radd(a Rat,b Rat)Rat{return rat(a.n*b.d+b.n*a.d,a.d*b.d)}
fn rsub(a Rat,b Rat)Rat{return rat(a.n*b.d-b.n*a.d,a.d*b.d)}
fn rmul(a Rat,b Rat)Rat{return rat(a.n*b.n,a.d*b.d)}
fn rdiv(a Rat,b Rat)Rat{return rat(a.n*b.d,a.d*b.n)}
fn rcmp(a Rat,b Rat)int{l:=a.n*b.d;r:=b.n*a.d;if l<r{return -1};if l>r{return 1};return 0}
fn peq(a RPt,b RPt)bool{return rcmp(a.x,b.x)==0&&rcmp(a.y,b.y)==0}
fn pless(a RPt,b RPt)bool{return rcmp(a.x,b.x)<0||(rcmp(a.x,b.x)==0&&rcmp(a.y,b.y)<0)}
fn orient(a Pt,b Pt,c Pt)int{v:=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);if v>0{return 1};if v<0{return -1};return 0}
fn breakpoint(p Pt,q Pt,line_y f64)f64{if math.abs(p.y-q.y)<eps{return(p.x+q.x)*0.5};dp:=p.y-line_y;dq:=q.y-line_y;a:=q.y-p.y;b:= -2.0*p.x*dq+2.0*q.x*dp;c:=(p.x*p.x+p.y*p.y-line_y*line_y)*dq-(q.x*q.x+q.y*q.y-line_y*line_y)*dp;mut disc:=b*b-4.0*a*c;if disc<0.0&&disc> -eps{disc=0.0};root:=math.sqrt(disc);r1:=(-b-root)/(2.0*a);r2:=(-b+root)/(2.0*a);if p.y<q.y{return math.max(r1,r2)};return math.min(r1,r2)}
fn circle(a Pt,b Pt,c Pt,sweep f64,arc int,left int,right int)(bool,Circle){if orient(a,b,c)>=0{return false,Circle{}};aa:=a.x*a.x+a.y*a.y;bb:=b.x*b.x+b.y*b.y;cc:=c.x*c.x+c.y*c.y;d:=2.0*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y));if math.abs(d)<eps{return false,Circle{}};x:=(aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y))/d;y:=(aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x))/d;dx:=x-a.x;dy:=y-a.y;bottom:=y-math.sqrt(dx*dx+dy*dy);if !(bottom<sweep-eps){return false,Circle{}};return true,Circle{bottom,x,arc,left,right}}
fn dist(p RPt,a i64,b i64,c i64)Rat{return rsub(radd(rmul(rat(a,1),p.x),rmul(rat(b,1),p.y)),rat(c,1))}
fn intersection(p RPt,q RPt,dp Rat,dq Rat)RPt{t:=rdiv(dp,rsub(dp,dq));return RPt{radd(p.x,rmul(t,rsub(q.x,p.x))),radd(p.y,rmul(t,rsub(q.y,p.y)))}}
fn push(mut p [vmax]RPt,mut n int,q RPt){if n==0||!peq(p[n-1],q){p[n]=q;n++}}
fn clip(mut poly [vmax]RPt,count int,a i64,b i64,c i64)int{mut next:=[vmax]RPt{};mut n:=0;for i in 0..count{p:=poly[i];q:=poly[(i+1)%count];dp:=dist(p,a,b,c);dq:=dist(q,a,b,c);pin:=dp.n<=0;qin:=dq.n<=0;if pin&&qin{push(mut next,mut n,q)}else if pin&&!qin{push(mut next,mut n,intersection(p,q,dp,dq))}else if !pin&&qin{push(mut next,mut n,intersection(p,q,dp,dq));push(mut next,mut n,q)}};if n>1&&peq(next[0],next[n-1]){n--};for i in 0..n{poly[i]=next[i]};return n}
fn valid(input &i64,n int)bool{unsafe{for i in 0..n{for j in i+1..n{if input[1+2*i]==input[1+2*j]&&input[2+2*i]==input[2+2*j]{return false};if input[2+2*i]==input[2+2*j]{return false}}};for i in 0..n{for j in i+1..n{for k in j+1..n{ax:=input[1+2*i];ay:=input[2+2*i];bx:=input[1+2*j];by:=input[2+2*j];cx:=input[1+2*k];cy:=input[2+2*k];if (bx-ax)*(cy-ay)==(by-ay)*(cx-ax){return false}}}};for i in 0..n{for j in i+1..n{for k in j+1..n{for l in k+1..n{ax:=input[1+2*i]-input[1+2*l];ay:=input[2+2*i]-input[2+2*l];bx:=input[1+2*j]-input[1+2*l];by:=input[2+2*j]-input[2+2*l];cx:=input[1+2*k]-input[1+2*l];cy:=input[2+2*k]-input[2+2*l];aa:=ax*ax+ay*ay;bb:=bx*bx+by*by;cc:=cx*cx+cy*cy;d:=ax*(by*cc-bb*cy)-ay*(bx*cc-bb*cx)+aa*(bx*cy-by*cx);if d==0{return false}}}}};return true}}
fn put(out &u8,slot int,v i64){bits:=u64(v);for i in 0..8{unsafe{out[slot*8+i]=u8(bits>>(i*8))}}}
@[export:'fortune_voronoi']
pub fn fortune_voronoi(input &i64,length usize,output &u8,capacity usize)i64{
 if isnil(input)||length<3{return -1};n64:=unsafe{input[0]};if n64<1||n64>nmax||length!=usize(1+2*n64){return -1};n:=int(n64);unsafe{for i in 0..n{if input[1+2*i]< -8||input[1+2*i]>8||input[2+2*i]< -8||input[2+2*i]>8{return -1}}};if !valid(input,n){return -1}
 mut sites:=[nmax]Pt{};mut order:=[nmax]int{};unsafe{for i in 0..n{sites[i]=Pt{f64(input[1+2*i]),f64(input[2+2*i])};order[i]=i}};for i in 1..n{v:=order[i];mut j:=i;for j>0&&sites[order[j-1]].y<sites[v].y{order[j]=order[j-1];j--};order[j]=v}
 mut arcs:=[amax]Arc{};mut arc_count:=1;mut first:=0;arcs[0]=Arc{order[0],-1,-1,true};mut next_site:=1;mut sweep:=sites[order[0]].y;mut adjacent:=[nmax][nmax]bool{}
 for next_site<n||first>=0{mut best:=Circle{};mut has:=false;mut b:=first;for b>=0{l:=arcs[b].prev;r:=arcs[b].next;if l>=0&&r>=0{si:=arcs[l].site;sj:=arcs[b].site;sk:=arcs[r].site;if si!=sj&&sj!=sk&&si!=sk{ok,cand:=circle(sites[si],sites[sj],sites[sk],sweep,b,l,r);if ok&&(!has||cand.y>best.y+eps||(math.abs(cand.y-best.y)<=eps&&b<best.arc)){best=cand;has=true}}};b=arcs[b].next};do_site:=next_site<n&&(!has||sites[order[next_site]].y>best.y+eps);if !do_site&&!has{break};if do_site{site:=order[next_site];next_site++;sweep=sites[site].y;mut arc:=first;for arcs[arc].next>=0{right:=arcs[arc].next;if sites[site].x<breakpoint(sites[arcs[arc].site],sites[arcs[right].site],sweep){break};arc=right};old_next:=arcs[arc].next;old_site:=arcs[arc].site;if arc_count+2>amax{return -1};middle:=arc_count;arc_count++;arcs[middle]=Arc{site,arc,-1,true};right:=arc_count;arc_count++;arcs[right]=Arc{old_site,middle,old_next,true};arcs[arc].next=middle;arcs[middle].next=right;if old_next>=0{arcs[old_next].prev=right};adjacent[old_site][site]=true;adjacent[site][old_site]=true}else{arc:=best.arc;left:=best.left;right:=best.right;if !arcs[arc].active||arcs[arc].prev!=left||arcs[arc].next!=right{return -1};sweep=best.y;ls:=arcs[left].site;rs:=arcs[right].site;adjacent[ls][rs]=true;adjacent[rs][ls]=true;arcs[left].next=right;arcs[right].prev=left;arcs[arc].active=false}}
 mut values:=[omax]i64{};mut used:=0;values[used]=i64(n);used++;for i in 0..n{mut poly:=[vmax]RPt{};poly[0]=RPt{Rat{-16,1},Rat{-16,1}};poly[1]=RPt{Rat{16,1},Rat{-16,1}};poly[2]=RPt{Rat{16,1},Rat{16,1}};poly[3]=RPt{Rat{-16,1},Rat{16,1}};mut count:=4;for j in 0..n{if adjacent[i][j]{unsafe{x:=input[1+2*j];y:=input[2+2*j];sx:=input[1+2*i];sy:=input[2+2*i];count=clip(mut poly,count,2*(x-sx),2*(y-sy),x*x+y*y-sx*sx-sy*sy)}}};if count<3||used+2+4*count>omax{return -1};mut start:=0;for j in 1..count{if pless(poly[j],poly[start]){start=j}};values[used]=i64(i);used++;values[used]=i64(count);used++;for j in 0..count{p:=poly[(start+j)%count];values[used]=p.x.n;used++;values[used]=p.x.d;used++;values[used]=p.y.n;used++;values[used]=p.y.d;used++}}
 bytes:=used*8;if isnil(output)||capacity<usize(bytes){return -2};for i in 0..used{put(output,i,values[i])};return i64(bytes)
}
