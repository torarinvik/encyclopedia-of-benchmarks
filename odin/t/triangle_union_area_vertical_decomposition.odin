package triangle_union_area_vertical_decomposition

import "core:c"

MT :: 3
MS :: 9
ME :: 45
Rat :: struct { n,d:i64 }
Seg :: struct { x0,y0,x1,y1:i64, id:int }
Interval :: struct { lo,hi:Rat, low,high:Seg, li,hiid:int }
abs64 :: proc(x:i64)->i64{return if x<0 {-x}else{x}}
gcd64 :: proc(a0,b0:i64)->i64{a,b:=abs64(a0),abs64(b0);for b!=0{t:=a%b;a=b;b=t};return if a==0 {1}else{a}}
rat :: proc(n0,d0:i64)->Rat{n,d:=n0,d0;if d<0{n=-n;d=-d};g:=gcd64(n,d);return Rat{n/g,d/g}}
radd :: proc(a,b:Rat)->Rat{return rat(a.n*b.d+b.n*a.d,a.d*b.d)}
rsub :: proc(a,b:Rat)->Rat{return rat(a.n*b.d-b.n*a.d,a.d*b.d)}
rmul :: proc(a,b:Rat)->Rat{return rat(a.n*b.n,a.d*b.d)}
rdiv :: proc(a,b:Rat)->Rat{return rat(a.n*b.d,a.d*b.n)}
rcmp :: proc(a,b:Rat)->int{x,y:=a.n*b.d,b.n*a.d;return if x<y {-1}else if x>y {1}else{0}}
cross :: proc(ax,ay,bx,by:i64)->i64{return ax*by-ay*bx}
orient :: proc(a,b,c0:[2]i64)->i64{return cross(b[0]-a[0],b[1]-a[1],c0[0]-a[0],c0[1]-a[1])}
yat :: proc(s:Seg,x:Rat)->Rat{return radd(rat(s.y0,1),rmul(rat(s.y1-s.y0,s.x1-s.x0),rsub(x,rat(s.x0,1))))}
intersection :: proc(a,b:Seg,x:^Rat)->bool{rx,ry,sx,sy:=a.x1-a.x0,a.y1-a.y0,b.x1-b.x0,b.y1-b.y0;den:=cross(rx,ry,sx,sy);if den==0{return false};qx,qy:=b.x0-a.x0,b.y0-a.y0;t,u:=rat(cross(qx,qy,sx,sy),den),rat(cross(qx,qy,rx,ry),den);if rcmp(t,rat(0,1))<0||rcmp(t,rat(1,1))>0||rcmp(u,rat(0,1))<0||rcmp(u,rat(1,1))>0{return false};x^=radd(rat(a.x0,1),rmul(t,rat(rx,1)));return true}
add_event :: proc(events:^ [ME]Rat,n:^int,x:Rat){for i:=0;i<n^;i+=1{if rcmp(events^[i],x)==0{return}};events^[n^]=x;n^+=1}
integrate :: proc(area:^Rat,low,high:Seg,xl,xr:Rat){h0,h1:=rsub(yat(high,xl),yat(low,xl)),rsub(yat(high,xr),yat(low,xr));area^=radd(area^,rmul(rsub(xr,xl),rdiv(radd(h0,h1),rat(2,1))))}
less_interval :: proc(a,b:Interval)->bool{c:=rcmp(a.lo,b.lo);if c!=0{return c<0};if a.li!=b.li{return a.li<b.li};h:=rcmp(a.hi,b.hi);if h!=0{return h<0};return a.hiid<b.hiid}

@(export)
triangle_union_area_vertical_decomposition :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
    if input==nil||length<1||length>20 do return -1
    nv:=input[0];if nv<1||nv>3||length!=c.size_t(1+6*nv) do return -1;n:=int(nv)
    p:[MT][3][2]i64
    for t:=0;t<n;t+=1{for j:=0;j<3;j+=1{for k:=0;k<2;k+=1{v:=input[1+6*t+2*j+k];if v< -1||v>1 do return -1;p[t][j][k]=v}};if (p[t][0]==p[t][1])||(p[t][0]==p[t][2])||(p[t][1]==p[t][2])||orient(p[t][0],p[t][1],p[t][2])==0 do return -1}
    seg:[MS]Seg;events:[ME]Rat;ns,ne:=0,0
    for t:=0;t<n;t+=1{for j:=0;j<3;j+=1{k:=(j+1)%3;a,b:=p[t][j],p[t][k];seg[ns]=Seg{a[0],a[1],b[0],b[1],3*t+j};add_event(&events,&ne,rat(a[0],1));ns+=1}}
    for i:=0;i<ns;i+=1{for j:=i+1;j<ns;j+=1{var x:Rat;if intersection(seg[i],seg[j],&x){add_event(&events,&ne,x)}}}
    for i:=1;i<ne;i+=1{v:=events[i];j:=i;for j>0&&rcmp(v,events[j-1])<0{events[j]=events[j-1];j-=1};events[j]=v}
    area:=rat(0,1);for e:=0;e<ne-1;e+=1{xl,xr:=events[e],events[e+1];if rcmp(xl,xr)>=0{continue};xm:=rdiv(radd(xl,xr),rat(2,1));var iv:[MT]Interval;ni:=0
        for t:=0;t<n;t+=1{var cs:[3]Seg;var ys:[3]Rat;count:=0;for j:=0;j<3;j+=1{s:=seg[3*t+j];if s.x0!=s.x1&&rcmp(xm,rat(min(s.x0,s.x1),1))>0&&rcmp(xm,rat(max(s.x0,s.x1),1))<0{cs[count]=s;ys[count]=yat(s,xm);count+=1}};if count==0{continue};if count!=2 do return -1;sw:=rcmp(ys[0],ys[1])>0||(rcmp(ys[0],ys[1])==0&&cs[0].id>cs[1].id);if sw{iv[ni]=Interval{ys[1],ys[0],cs[1],cs[0],cs[1].id,cs[0].id}}else{iv[ni]=Interval{ys[0],ys[1],cs[0],cs[1],cs[0].id,cs[1].id}};ni+=1}
        for i:=1;i<ni;i+=1{v:=iv[i];j:=i;for j>0&&less_interval(v,iv[j-1]){iv[j]=iv[j-1];j-=1};iv[j]=v}
        have:=false;var low,high:Seg;top:=rat(0,1);hid:=0;for i:=0;i<ni;i+=1{v:=iv[i];if !have{low=v.low;high=v.high;top=v.hi;hid=v.hiid;have=true;continue};if rcmp(v.lo,top)<=0{c0:=rcmp(v.hi,top);if c0>0||(c0==0&&v.hiid<hid){high=v.high;top=v.hi;hid=v.hiid}}else{integrate(&area,low,high,xl,xr);low=v.low;high=v.high;top=v.hi;hid=v.hiid}};if have{integrate(&area,low,high,xl,xr)}
    }
    if area.n<0||area.d<=0||area.n>11289600||area.d>2822400 do return -1
    if output==nil||capacity<16 do return -2
    for j:=0;j<8;j+=1{output[j]=u8((u64(area.n)>>(8*j))&255);output[8+j]=u8((u64(area.d)>>(8*j))&255)}
    return 16
}
