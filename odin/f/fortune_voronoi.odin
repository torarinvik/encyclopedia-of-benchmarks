package fortune_voronoi
import "core:c"
import "core:math"

N :: 8
MAX_ARCS :: 15
MAX_VERTICES :: 32
MAX_OUTPUT :: 1024
EPS :: 1.0e-10
Point :: struct{x,y:f64}
Arc :: struct{site,prev,next:int,active:bool}
Circle :: struct{y,x:f64,arc,left,right:int}
Rat :: struct{n,d:i64}
RPoint :: struct{x,y:Rat}
rat :: proc "contextless" (n0,d0:i64)->Rat{n,d:=n0,d0;if d<0{n= -n;d= -d};a:=if n<0{-n}else{n};b:=if d<0{-d}else{d};for b!=0{t:=a%b;a=b;b=t};g:=if a==0{i64(1)}else{a};return Rat{n/g,d/g}}
radd :: proc "contextless" (a,b:Rat)->Rat{return rat(a.n*b.d+b.n*a.d,a.d*b.d)}
rsub :: proc "contextless" (a,b:Rat)->Rat{return rat(a.n*b.d-b.n*a.d,a.d*b.d)}
rmul :: proc "contextless" (a,b:Rat)->Rat{return rat(a.n*b.n,a.d*b.d)}
rdiv :: proc "contextless" (a,b:Rat)->Rat{return rat(a.n*b.d,a.d*b.n)}
rcmp :: proc "contextless" (a,b:Rat)->int{l:=a.n*b.d;r:=b.n*a.d;if l<r{return -1};if l>r{return 1};return 0}
peq :: proc "contextless" (a,b:RPoint)->bool{return rcmp(a.x,b.x)==0&&rcmp(a.y,b.y)==0}
pless :: proc "contextless" (a,b:RPoint)->bool{return rcmp(a.x,b.x)<0||(rcmp(a.x,b.x)==0&&rcmp(a.y,b.y)<0)}
orient :: proc "contextless" (a,b,c:Point)->int{v:=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);if v>0{return 1};if v<0{return -1};return 0}
breakpoint :: proc "contextless" (p,q:Point,line_y:f64)->f64{if math.abs_f64(p.y-q.y)<EPS{return(p.x+q.x)*0.5};dp:=p.y-line_y;dq:=q.y-line_y;a:=q.y-p.y;b:= -2.0*p.x*dq+2.0*q.x*dp;cc:=(p.x*p.x+p.y*p.y-line_y*line_y)*dq-(q.x*q.x+q.y*q.y-line_y*line_y)*dp;disc:=b*b-4.0*a*cc;mut d:=disc;if d<0&&d> -EPS{d=0};root:=math.sqrt_f64(d);r1:=(-b-root)/(2*a);r2:=(-b+root)/(2*a);if p.y<q.y{return math.max(r1,r2)};return math.min(r1,r2)}
circle :: proc "contextless" (a,b,c:Point,sweep:f64,arc,left,right:int)->(bool,Circle){if orient(a,b,c)>=0{return false,{}};aa:=a.x*a.x+a.y*a.y;bb:=b.x*b.x+b.y*b.y;cc:=c.x*c.x+c.y*c.y;d:=2.0*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y));if math.abs_f64(d)<EPS{return false,{}};x:=(aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y))/d;y:=(aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x))/d;dx:=x-a.x;dy:=y-a.y;bottom:=y-math.sqrt_f64(dx*dx+dy*dy);if !(bottom<sweep-EPS){return false,{}};return true,Circle{bottom,x,arc,left,right}}
dist :: proc "contextless" (p:RPoint,a,b,cc:i64)->Rat{return rsub(radd(rmul(rat(a,1),p.x),rmul(rat(b,1),p.y)),rat(cc,1))}
intersection :: proc "contextless" (p,q:RPoint,dp,dq:Rat)->RPoint{t:=rdiv(dp,rsub(dp,dq));return RPoint{radd(p.x,rmul(t,rsub(q.x,p.x))),radd(p.y,rmul(t,rsub(q.y,p.y)))}}
push :: proc "contextless" (p:[^]RPoint,n:^int,q:RPoint){if n^==0||!peq(p[n^-1],q){p[n^]=q;n^+=1}}
clip :: proc "contextless" (poly:[^]RPoint,count:int,a,b,cc:i64)->int{next:[MAX_VERTICES]RPoint;mut n:=0;for i:=0;i<count;i+=1{p:=poly[i];q:=poly[(i+1)%count];dp:=dist(p,a,b,cc);dq:=dist(q,a,b,cc);pin:=dp.n<=0;qin:=dq.n<=0;if pin&&qin{push(&next[0],&n,q)}else if pin&&!qin{push(&next[0],&n,intersection(p,q,dp,dq))}else if !pin&&qin{push(&next[0],&n,intersection(p,q,dp,dq));push(&next[0],&n,q)}};if n>1&&peq(next[0],next[n-1]){n-=1};for i:=0;i<n;i+=1{poly[i]=next[i]};return n}
valid :: proc "contextless" (input:[^]i64,n:int)->bool{for i:=0;i<n;i+=1{for j:=i+1;j<n;j+=1{if input[1+2*i]==input[1+2*j]&&input[2+2*i]==input[2+2*j]{return false};if input[2+2*i]==input[2+2*j]{return false}}};for i:=0;i<n;i+=1{for j:=i+1;j<n;j+=1{for k:=j+1;k<n;k+=1{ax:=input[1+2*i];ay:=input[2+2*i];bx:=input[1+2*j];by:=input[2+2*j];cx:=input[1+2*k];cy:=input[2+2*k];if (bx-ax)*(cy-ay)==(by-ay)*(cx-ax){return false}}}};for i:=0;i<n;i+=1{for j:=i+1;j<n;j+=1{for k:=j+1;k<n;k+=1{for l:=k+1;l<n;l+=1{ax:=input[1+2*i]-input[1+2*l];ay:=input[2+2*i]-input[2+2*l];bx:=input[1+2*j]-input[1+2*l];by:=input[2+2*j]-input[2+2*l];cx:=input[1+2*k]-input[1+2*l];cy:=input[2+2*k]-input[2+2*l];aa:=ax*ax+ay*ay;bb:=bx*bx+by*by;cc:=cx*cx+cy*cy;det:=ax*(by*cc-bb*cy)-ay*(bx*cc-bb*cx)+aa*(bx*cy-by*cx);if det==0{return false}}}}};return true}
put :: proc "contextless" (out:[^]u8,slot:int,v:i64){bits:=u64(v);for i:=0;i<8;i+=1{out[slot*8+i]=u8(bits>>u64(i*8))}}
@(export)
fortune_voronoi :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3 do return -1;n64:=input[0];if n64<1||n64>N||int(length)!=1+2*int(n64) do return -1;n:=int(n64);for i:=0;i<n;i+=1{if input[1+2*i]< -8||input[1+2*i]>8||input[2+2*i]< -8||input[2+2*i]>8 do return -1};if !valid(input,n) do return -1;
 sites:[N]Point;order:[N]int;for i:=0;i<n;i+=1{sites[i]=Point{f64(input[1+2*i]),f64(input[2+2*i])};order[i]=i};for i:=1;i<n;i+=1{v:=order[i];j:=i;for j>0&&sites[order[j-1]].y<sites[v].y{order[j]=order[j-1];j-=1};order[j]=v}
 arcs:[MAX_ARCS]Arc;arc_count:=1;first:=0;arcs[0]=Arc{order[0],-1,-1,true};next_site:=1;sweep:=sites[order[0]].y;adjacent:[N][N]bool
 for next_site<n||first>=0{best:Circle;has:=false;b:=first;for b>=0{l:=arcs[b].prev;r:=arcs[b].next;if l>=0&&r>=0{si:=arcs[l].site;sj:=arcs[b].site;sk:=arcs[r].site;if si!=sj&&sj!=sk&&si!=sk{ok,cand:=circle(sites[si],sites[sj],sites[sk],sweep,b,l,r);if ok&&(!has||cand.y>best.y+EPS||(math.abs_f64(cand.y-best.y)<=EPS&&b<best.arc)){best=cand;has=true}}};b=arcs[b].next};do_site:=next_site<n&&(!has||sites[order[next_site]].y>best.y+EPS);if !do_site&&!has{break};if do_site{site:=order[next_site];next_site+=1;sweep=sites[site].y;arc:=first;for arcs[arc].next>=0{right:=arcs[arc].next;if sites[site].x<breakpoint(sites[arcs[arc].site],sites[arcs[right].site],sweep){break};arc=right};old_next:=arcs[arc].next;old_site:=arcs[arc].site;if arc_count+2>MAX_ARCS do return -1;middle:=arc_count;arc_count+=1;arcs[middle]=Arc{site,arc,-1,true};right:=arc_count;arc_count+=1;arcs[right]=Arc{old_site,middle,old_next,true};arcs[arc].next=middle;arcs[middle].next=right;if old_next>=0{arcs[old_next].prev=right};adjacent[old_site][site]=true;adjacent[site][old_site]=true}else{arc:=best.arc;left:=best.left;right:=best.right;if !arcs[arc].active||arcs[arc].prev!=left||arcs[arc].next!=right do return -1;sweep=best.y;ls:=arcs[left].site;rs:=arcs[right].site;adjacent[ls][rs]=true;adjacent[rs][ls]=true;arcs[left].next=right;arcs[right].prev=left;arcs[arc].active=false}}
 values:[MAX_OUTPUT]i64;used:=0;values[used]=i64(n);used+=1;for i:=0;i<n;i+=1{poly:[MAX_VERTICES]RPoint;poly[0]=RPoint{Rat{-16,1},Rat{-16,1}};poly[1]=RPoint{Rat{16,1},Rat{-16,1}};poly[2]=RPoint{Rat{16,1},Rat{16,1}};poly[3]=RPoint{Rat{-16,1},Rat{16,1}};count:=4;for j:=0;j<n;j+=1{if adjacent[i][j]{x:=input[1+2*j];y:=input[2+2*j];sx:=input[1+2*i];sy:=input[2+2*i];count=clip(&poly[0],count,2*(x-sx),2*(y-sy),x*x+y*y-sx*sx-sy*sy)}};if count<3||used+2+4*count>MAX_OUTPUT do return -1;start:=0;for j:=1;j<count;j+=1{if pless(poly[j],poly[start]){start=j}};values[used]=i64(i);used+=1;values[used]=i64(count);used+=1;for j:=0;j<count;j+=1{p:=poly[(start+j)%count];values[used]=p.x.n;used+=1;values[used]=p.x.d;used+=1;values[used]=p.y.n;used+=1;values[used]=p.y.d;used+=1}}
 bytes:=used*8;if output==nil||int(capacity)<bytes do return -2;for i:=0;i<used;i+=1{put(output,i,values[i])};return i64(bytes)
}
