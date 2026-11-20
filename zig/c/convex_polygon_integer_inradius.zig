// Independently authored draft; not compiled or run.
const Line = struct { a:i64, b:i64, c:i64, norm:i64 };
const Point = struct { x:i64, y:i64, den:i64 };
fn abs64(x:i64) i64 { return if (x<0) -x else x; }
fn gcd64(x:i64,y:i64) i64 {
    var a=abs64(x); var b=abs64(y);
    while (b!=0) { const r=@mod(a,b); a=b; b=r; }
    return a;
}
fn half(l:Line) u8 { return if (l.b>0 or (l.b==0 and l.a>=0)) 0 else 1; }
fn before(a:Line,b:Line) bool {
    const ha=half(a); const hb=half(b);
    if (ha!=hb) return ha<hb;
    const cross=a.a*b.b-a.b*b.a;
    return if (cross!=0) cross>0 else a.c<b.c;
}
fn intersect(a:Line,b:Line) ?Point {
    var den=a.a*b.b-b.a*a.b;
    if (den==0) return null;
    var x=a.c*b.b-a.b*b.c; var y=a.a*b.c-a.c*b.a;
    if (den<0) { den=-den; x=-x; y=-y; }
    return .{ .x=x, .y=y, .den=den };
}
fn outside(l:Line,p:Point) bool { return l.a*p.x+l.b*p.y>l.c*p.den; }
fn feasible(lines:[]const Line,radius:i64) bool {
    var queue:[16]Line=undefined; var head:usize=0; var tail:usize=0;
    for (lines) |line| {
        var h=line; h.c=h.c*32768-(radius*32768-1)*h.norm;
        if (tail>head and queue[tail-1].a==h.a and queue[tail-1].b==h.b) {
            if (h.c>=queue[tail-1].c) continue;
            tail-=1;
        }
        while (tail-head>1) {
            const p=intersect(queue[tail-2],queue[tail-1]) orelse break;
            if (!outside(h,p)) break;
            tail-=1;
        }
        while (tail-head>1) {
            const p=intersect(queue[head],queue[head+1]) orelse break;
            if (!outside(h,p)) break;
            head+=1;
        }
        if (tail>head and queue[tail-1].a*h.b-queue[tail-1].b*h.a==0) return false;
        queue[tail]=h; tail+=1;
    }
    while (tail-head>2) {
        const p=intersect(queue[tail-2],queue[tail-1]) orelse break;
        if (!outside(queue[head],p)) break;
        tail-=1;
    }
    while (tail-head>2) {
        const p=intersect(queue[head],queue[head+1]) orelse break;
        if (!outside(queue[tail-1],p)) break;
        head+=1;
    }
    if (tail-head<3) return false;
    for (head..tail) |i| {
        const j=if (i+1==tail) head else i+1;
        if (intersect(queue[i],queue[j])==null) return false;
    }
    return true;
}
export fn convex_polygon_integer_inradius(input:?[*]const i64,length:usize) i64 {
    if (input==null or length<1 or length>38) return -1;
    const values=input.?;
    if (values[0]<0 or values[0]>12) return -1;
    const n:usize=@intCast(values[0]);
    if (length!=1+3*n) return -1;
    var lines:[16]Line=undefined;
    for (0..n) |i| {
        const a=values[1+3*i]; const b=values[2+3*i]; const c=values[3+3*i];
        if (a < -15 or a>15 or b < -15 or b>15 or c < -128 or c>128) return -1;
        const squared=a*a+b*b; var norm:i64=0;
        while (norm*norm<squared) norm+=1;
        if (norm==0 or norm*norm!=squared or gcd64(a,b)!=1) return -1;
        lines[i]=.{.a=a,.b=b,.c=c,.norm=norm};
    }
    lines[n]=.{.a=1,.b=0,.c=256,.norm=1}; lines[n+1]=.{.a=0,.b=1,.c=256,.norm=1};
    lines[n+2]=.{.a= -1,.b=0,.c=256,.norm=1}; lines[n+3]=.{.a=0,.b= -1,.c=256,.norm=1};
    const count=n+4; var scratch:[16]Line=undefined; var width:usize=1;
    while (width<count) : (width*=2) {
        var start:usize=0;
        while (start<count) : (start+=2*width) {
            const middle=@min(start+width,count); const end=@min(start+2*width,count);
            var i=start; var j=middle; var k=start;
            while (i<middle and j<end) : (k+=1) {
                if (before(lines[j],lines[i])) { scratch[k]=lines[j]; j+=1; }
                else { scratch[k]=lines[i]; i+=1; }
            }
            while (i<middle) : (i+=1) { scratch[k]=lines[i]; k+=1; }
            while (j<end) : (j+=1) { scratch[k]=lines[j]; k+=1; }
        }
        for (0..count) |i| lines[i]=scratch[i];
    }
    if (!feasible(lines[0..count],0)) return -2;
    var low:i64=0; var high:i64=257;
    while (high-low>1) {
        const mid=@divTrunc(low+high,2);
        if (feasible(lines[0..count],mid)) { low=mid; } else { high=mid; }
    }
    return low;
}
