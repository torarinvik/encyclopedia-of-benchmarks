const MT: usize = 3;
const MS: usize = 9;
const ME: usize = 45;
const Rat = struct { n: i64, d: i64 };
const Seg = struct { x0:i64=0,y0:i64=0,x1:i64=0,y1:i64=0,id:i32=0 };
const Interval = struct { lo:Rat,hi:Rat,low:Seg,high:Seg,li:i32,hiid:i32 };
fn abs64(x:i64)i64{return if(x<0)-x else x;}
fn gcd(a0:i64,b0:i64)i64{var a=abs64(a0);var b=abs64(b0);while(b!=0){const t=@rem(a,b);a=b;b=t;}return if(a==0)1 else a;}
fn rat(n0:i64,d0:i64)Rat{var n=n0;var d=d0;if(d<0){n=-n;d=-d;}const g=gcd(n,d);return .{.n=@divTrunc(n,g),.d=@divTrunc(d,g)};}
fn add(a:Rat,b:Rat)Rat{return rat(a.n*b.d+b.n*a.d,a.d*b.d);}
fn sub(a:Rat,b:Rat)Rat{return rat(a.n*b.d-b.n*a.d,a.d*b.d);}
fn mul(a:Rat,b:Rat)Rat{return rat(a.n*b.n,a.d*b.d);}
fn divv(a:Rat,b:Rat)Rat{return rat(a.n*b.d,a.d*b.n);}
fn cmp(a:Rat,b:Rat)i32{const x=a.n*b.d;const y=b.n*a.d;return if(x<y)-1 else if(x>y)1 else 0;}
fn cross(ax:i64,ay:i64,bx:i64,by:i64)i64{return ax*by-ay*bx;}
fn orient(a:[2]i64,b:[2]i64,c:[2]i64)i64{return cross(b[0]-a[0],b[1]-a[1],c[0]-a[0],c[1]-a[1]);}
fn yAt(s:Seg,x:Rat)Rat{return add(rat(s.y0,1),mul(rat(s.y1-s.y0,s.x1-s.x0),sub(x,rat(s.x0,1))));}
fn intersection(a:Seg,b:Seg)?Rat{const rx=a.x1-a.x0;const ry=a.y1-a.y0;const sx=b.x1-b.x0;const sy=b.y1-b.y0;const den=cross(rx,ry,sx,sy);if(den==0)return null;const qx=b.x0-a.x0;const qy=b.y0-a.y0;const t=rat(cross(qx,qy,sx,sy),den);const u=rat(cross(qx,qy,rx,ry),den);if(cmp(t,rat(0,1))<0 or cmp(t,rat(1,1))>0 or cmp(u,rat(0,1))<0 or cmp(u,rat(1,1))>0)return null;return add(rat(a.x0,1),mul(t,rat(rx,1)));}
fn pushEvent(events:*[ME]Rat,n:*usize,x:Rat)void{for(0..n.*)|i|{if(cmp(events.*[i],x)==0)return;}events.*[n.*]=x;n.*+=1;}
fn integrate(area:*Rat,low:Seg,high:Seg,xl:Rat,xr:Rat)void{const h0=sub(yAt(high,xl),yAt(low,xl));const h1=sub(yAt(high,xr),yAt(low,xr));area.*=add(area.*,mul(sub(xr,xl),divv(add(h0,h1),rat(2,1))));}
fn lessI(a:Interval,b:Interval)bool{const c=cmp(a.lo,b.lo);if(c!=0)return c<0;if(a.li!=b.li)return a.li<b.li;const h=cmp(a.hi,b.hi);if(h!=0)return h<0;return a.hiid<b.hiid;}

export fn triangle_union_area_vertical_decomposition(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<1 or length>20)return -1;const input=input_opt.?;const nv=input[0];if(nv<1 or nv>3 or length!=1+6*@as(usize,@intCast(nv)))return -1;const n:usize=@intCast(nv);
    var tri=[_] [3][2]i64{.{.{0,0},.{0,0},.{0,0}}}**MT;
    for(0..n)|t|{for(0..3)|j|{const x=input[1+6*t+2*j];const y=input[2+6*t+2*j];if(x< -1 or x>1 or y< -1 or y>1)return -1;tri[t][j]=.{x,y};}if((tri[t][0][0]==tri[t][1][0] and tri[t][0][1]==tri[t][1][1]) or (tri[t][0][0]==tri[t][2][0] and tri[t][0][1]==tri[t][2][1]) or (tri[t][1][0]==tri[t][2][0] and tri[t][1][1]==tri[t][2][1]) or orient(tri[t][0],tri[t][1],tri[t][2])==0)return -1;}
    var seg=[_]Seg{.{}}**MS;var ns:usize=0;var events=[_]Rat{.{.n=0,.d=1}}**ME;var ne:usize=0;
    for(0..n)|t|{for(0..3)|j|{const k=(j+1)%3;const a=tri[t][j];const b=tri[t][k];seg[ns]=.{.x0=a[0],.y0=a[1],.x1=b[0],.y1=b[1],.id=@intCast(3*t+j)};pushEvent(&events,&ne,rat(a[0],1));ns+=1;}}
    for(0..ns)|i|{var j=i+1;while(j<ns):(j+=1){if(intersection(seg[i],seg[j]))|x|{pushEvent(&events,&ne,x);}}}
    var ei:usize=1;while(ei<ne):(ei+=1){const v=events[ei];var j=ei;while(j>0 and cmp(v,events[j-1])<0){events[j]=events[j-1];j-=1;}events[j]=v;}
    var area=rat(0,1);if(ne>1){for(0..ne-1)|e|{const xl=events[e];const xr=events[e+1];if(cmp(xl,xr)>=0)continue;const xm=divv(add(xl,xr),rat(2,1));var iv=[_]Interval{.{.lo=rat(0,1),.hi=rat(0,1),.low=.{},.high=.{},.li=0,.hiid=0}}**MT;var ni:usize=0;
        for(0..n)|t|{var cs=[_]Seg{.{}}**3;var ys=[_]Rat{.{.n=0,.d=1}}**3;var count:usize=0;for(0..3)|j|{const s=seg[3*t+j];const lo=@min(s.x0,s.x1);const hi=@max(s.x0,s.x1);if(s.x0!=s.x1 and cmp(xm,rat(lo,1))>0 and cmp(xm,rat(hi,1))<0){cs[count]=s;ys[count]=yAt(s,xm);count+=1;}}if(count==0)continue;if(count!=2)return -1;const sw=cmp(ys[0],ys[1])>0 or (cmp(ys[0],ys[1])==0 and cs[0].id>cs[1].id);if(sw){iv[ni]=.{.lo=ys[1],.hi=ys[0],.low=cs[1],.high=cs[0],.li=cs[1].id,.hiid=cs[0].id};}else{iv[ni]=.{.lo=ys[0],.hi=ys[1],.low=cs[0],.high=cs[1],.li=cs[0].id,.hiid=cs[1].id};}ni+=1;}
        var i:usize=1;while(i<ni):(i+=1){const v=iv[i];var j=i;while(j>0 and lessI(v,iv[j-1])){iv[j]=iv[j-1];j-=1;}iv[j]=v;}
        var have=false;var low:Seg=.{ };var high:Seg=.{ };var top=rat(0,1);var hid:i32=0;for(0..ni)|i|{const v=iv[i];if(!have){low=v.low;high=v.high;top=v.hi;hid=v.hiid;have=true;continue;}if(cmp(v.lo,top)<=0){const c=cmp(v.hi,top);if(c>0 or (c==0 and v.hiid<hid)){high=v.high;top=v.hi;hid=v.hiid;}}else{integrate(&area,low,high,xl,xr);low=v.low;high=v.high;top=v.hi;hid=v.hiid;}}if(have)integrate(&area,low,high,xl,xr);
    }}
    if(area.n<0 or area.d<=0 or area.n>11289600 or area.d>2822400)return -1;if(output_opt==null or capacity<16)return -2;const output=output_opt.?;for(0..8)|j|{output[j]=@truncate(@as(u64,@intCast(area.n))>>(8*j));output[8+j]=@truncate(@as(u64,@intCast(area.d))>>(8*j));}return 16;
}
