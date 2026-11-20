const V: usize = 6;
const X: usize = 36;
const NODES: usize = 42;
const WORDS: usize = 210;

const Rat = struct { n: i64, d: i64 };
const Point = struct { xn: i64, xd: i64, yn: i64, yd: i64 };
const Crossing = struct { p: Point, ta: Rat, tb: Rat, ae: bool, ax: bool, be: bool, bx: bool };
const Node = struct { p: Point, crossing: i32 };
const Ring = struct { points: [48]Point, count: usize };

fn abs64(x: i64) i64 { return if (x < 0) -x else x; }
fn gcd(a0: i64, b0: i64) i64 {
    var a = abs64(a0); var b = abs64(b0);
    while (b != 0) { const r = @mod(a,b); a=b; b=r; }
    return if (a == 0) 1 else a;
}
fn makeRat(n0: i64, d0: i64) Rat {
    var n=n0; var d=d0;
    if (d<0) { n=-n; d=-d; }
    const g=gcd(n,d); return .{.n=@divTrunc(n,g),.d=@divTrunc(d,g)};
}
fn lessRat(a: Rat,b: Rat) bool { return a.n*b.d < b.n*a.d; }
fn equalRat(a: Rat,b: Rat) bool { return a.n==b.n and a.d==b.d; }
fn lessPoint(a: Point,b: Point) bool {
    const ax=a.xn*b.xd; const bx=b.xn*a.xd;
    if (ax!=bx) return ax<bx;
    return a.yn*b.yd < b.yn*a.yd;
}
fn equalPoint(a: Point,b: Point) bool {
    return equalRat(.{.n=a.xn,.d=a.xd},.{.n=b.xn,.d=b.xd})
        and equalRat(.{.n=a.yn,.d=a.yd},.{.n=b.yn,.d=b.yd});
}
fn intPoint(x: i64,y: i64) Point { return .{.xn=x,.xd=1,.yn=y,.yd=1}; }
fn orient(ax:i64,ay:i64,bx:i64,by:i64,cx:i64,cy:i64) i64 {
    return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax);
}
fn onSegment(ax:i64,ay:i64,bx:i64,by:i64,px:i64,py:i64) bool {
    return orient(ax,ay,bx,by,px,py)==0 and px>=@min(ax,bx) and px<=@max(ax,bx)
        and py>=@min(ay,by) and py<=@max(ay,by);
}
// 0 disjoint, 1 proper crossing, 2 contact or collinear overlap.
fn relation(ax:i64,ay:i64,bx:i64,by:i64,cx:i64,cy:i64,dx:i64,dy:i64) i32 {
    const o1=orient(ax,ay,bx,by,cx,cy); const o2=orient(ax,ay,bx,by,dx,dy);
    const o3=orient(cx,cy,dx,dy,ax,ay); const o4=orient(cx,cy,dx,dy,bx,by);
    if (((o1>0 and o2<0) or (o1<0 and o2>0)) and ((o3>0 and o4<0) or (o3<0 and o4>0))) return 1;
    if ((o1==0 and onSegment(ax,ay,bx,by,cx,cy)) or (o2==0 and onSegment(ax,ay,bx,by,dx,dy))
        or (o3==0 and onSegment(cx,cy,dx,dy,ax,ay)) or (o4==0 and onSegment(cx,cy,dx,dy,bx,by))) return 2;
    return 0;
}
fn polyValid(p: *const [12]i64,n:usize) bool {
    var area:i64=0;
    for (0..n) |i| {
        const prev=(i+n-1)%n; const next=(i+1)%n;
        const x=p[2*i]; const y=p[2*i+1]; const nx=p[2*next]; const ny=p[2*next+1];
        area += x*ny-y*nx;
        if (orient(p[2*prev],p[2*prev+1],x,y,nx,ny)==0) return false;
        for (0..i) |j| if (x==p[2*j] and y==p[2*j+1]) { return false; };
    }
    if (area<=0) return false;
    for (0..n) |i| for (i+1..n) |j| {
        if (j==i+1 or (i==0 and j==n-1)) continue;
        const k=(i+1)%n; const l=(j+1)%n;
        if (relation(p[2*i],p[2*i+1],p[2*k],p[2*k+1],p[2*j],p[2*j+1],p[2*l],p[2*l+1])!=0) return false;
    };
    return true;
}
fn inside(x:i64,y:i64,p:*const [12]i64,n:usize) bool {
    var winding:i32=0;
    for (0..n) |i| {
        const j=(i+1)%n; const side=orient(p[2*i],p[2*i+1],p[2*j],p[2*j+1],x,y);
        if (p[2*i+1]<=y and y<p[2*j+1] and side>0) winding+=1
        else if (p[2*j+1]<=y and y<p[2*i+1] and side<0) winding-=1;
    }
    return winding!=0;
}
fn intersection(ax:i64,ay:i64,bx:i64,by:i64,cx:i64,cy:i64,dx:i64,dy:i64,ta:*Rat,tb:*Rat) Point {
    const rx=bx-ax; const ry=by-ay; const sx=dx-cx; const sy=dy-cy;
    var den=rx*sy-ry*sx; var tn=(cx-ax)*sy-(cy-ay)*sx; var un=(cx-ax)*ry-(cy-ay)*rx;
    if (den<0) {den=-den;tn=-tn;un=-un;}
    ta.*=makeRat(tn,den); tb.*=makeRat(un,den);
    const x=makeRat(ax*den+rx*tn,den); const y=makeRat(ay*den+ry*tn,den);
    return .{.xn=x.n,.xd=x.d,.yn=y.n,.yd=y.d};
}
fn store(out:[*]u8,offset:usize,value:i64) void {
    const bits:u64=@bitCast(value);
    for (0..8) |i| out[offset+i]=@truncate(bits >> @intCast(8*i));
}
fn canonicalize(rings:*[16]Ring,count:usize) void {
    for (0..count) |r| {
        var pivot:usize=0;
        for (1..rings[r].count) |i| if (lessPoint(rings[r].points[i],rings[r].points[pivot])) {pivot=i;};
        if (pivot>0) {
            var temp:[48]Point=@splat(intPoint(0,0));
            for (0..rings[r].count) |i| temp[i]=rings[r].points[(pivot+i)%rings[r].count];
            for (0..rings[r].count) |i| rings[r].points[i]=temp[i];
        }
    }
    for (1..count) |i| {
        const key=rings[i]; var j=i;
        while (j>0 and lessPoint(key.points[0],rings[j-1].points[0])) : (j-=1) rings[j]=rings[j-1];
        rings[j]=key;
    }
}
fn runWeiler(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize) i64 {
    if (input_opt==null or length<2 or length>27) return -1;
    const input=input_opt.?; const na64=input[0]; const nb64=input[1];
    if (na64<3 or na64>6 or nb64<3 or nb64>6 or length!=2+2*@as(usize,@intCast(na64+nb64))) return -1;
    const na:usize=@intCast(na64); const nb:usize=@intCast(nb64);
    var a:[12]i64=@splat(0); var b:[12]i64=@splat(0); var cursor:usize=2;
    for (0..2*na) |i| {const value=input[cursor];cursor+=1;if(value < -16 or value>16)return -1;a[i]=value;}
    for (0..2*nb) |i| {const value=input[cursor];cursor+=1;if(value < -16 or value>16)return -1;b[i]=value;}
    if (!polyValid(&a,na) or !polyValid(&b,nb)) return -1;
    var crossings:[X]Crossing=@splat(.{.p=intPoint(0,0),.ta=.{.n=0,.d=1},.tb=.{.n=0,.d=1},.ae=false,.ax=false,.be=false,.bx=false});
    var ev_a:[V][V]usize=@splat(@splat(0)); var ev_b:[V][V]usize=@splat(@splat(0));
    var cnt_a:[V]usize=@splat(0); var cnt_b:[V]usize=@splat(0); var xc:usize=0;
    for (0..na) |i| for (0..nb) |j| {
        const ai=(i+1)%na;const bj=(j+1)%nb;
        const rel=relation(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1],b[2*bj],b[2*bj+1]);
        if (rel==2) return -1;
        if (rel==1) {
            var c=crossings[xc]; c.p=intersection(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],&c.ta,&c.tb);
            const ab=orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*i],a[2*i+1]);
            const aa=orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*ai],a[2*ai+1]);
            const bb=orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1]);
            const ba=orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*bj],b[2*bj+1]);
            c.ae=ab<0 and aa>0;c.ax=ab>0 and aa<0;c.be=bb<0 and ba>0;c.bx=bb>0 and ba<0;
            if ((!c.ae and !c.ax) or (!c.be and !c.bx) or c.ae==c.be) return -1;
            crossings[xc]=c;ev_a[i][cnt_a[i]]=xc;ev_b[j][cnt_b[j]]=xc;cnt_a[i]+=1;cnt_b[j]+=1;xc+=1;
        }
    };
    var rings:[16]Ring=@splat(.{.points=@splat(intPoint(0,0)),.count=0});var rc:usize=0;
    if (xc==0) {
        if(inside(a[0],a[1],&b,nb)){for(0..na)|i|rings[0].points[i]=intPoint(a[2*i],a[2*i+1]);rings[0].count=na;rc=1;}
        else if(inside(b[0],b[1],&a,na)){for(0..nb)|i|rings[0].points[i]=intPoint(b[2*i],b[2*i+1]);rings[0].count=nb;rc=1;}
    } else {
        var nodes_a:[NODES]Node=@splat(.{.p=intPoint(0,0),.crossing=-1});var nodes_b:[NODES]Node=@splat(.{.p=intPoint(0,0),.crossing=-1});
        var ca:usize=0;var cb:usize=0;var pos_a:[X]usize=@splat(0);var pos_b:[X]usize=@splat(0);
        for(0..na)|edge|{nodes_a[ca]=.{.p=intPoint(a[2*edge],a[2*edge+1]),.crossing=-1};ca+=1;
            for(1..cnt_a[edge])|z|{const id=ev_a[edge][z];var k=z;while(k>0 and lessRat(crossings[id].ta,crossings[ev_a[edge][k-1]].ta)):(k-=1){ev_a[edge][k]=ev_a[edge][k-1];}ev_a[edge][k]=id;}
            for(0..cnt_a[edge])|z|{const id=ev_a[edge][z];nodes_a[ca]=.{.p=crossings[id].p,.crossing=@intCast(id)};pos_a[id]=ca;ca+=1;}}
        for(0..nb)|edge|{nodes_b[cb]=.{.p=intPoint(b[2*edge],b[2*edge+1]),.crossing=-1};cb+=1;
            for(1..cnt_b[edge])|z|{const id=ev_b[edge][z];var k=z;while(k>0 and lessRat(crossings[id].tb,crossings[ev_b[edge][k-1]].tb)):(k-=1){ev_b[edge][k]=ev_b[edge][k-1];}ev_b[edge][k]=id;}
            for(0..cnt_b[edge])|z|{const id=ev_b[edge][z];nodes_b[cb]=.{.p=crossings[id].p,.crossing=@intCast(id)};pos_b[id]=cb;cb+=1;}}
        var visited:[X]bool=@splat(false);
        for(0..ca)|start|{const sid_i=nodes_a[start].crossing;if(sid_i<0)continue;const sid:usize=@intCast(sid_i);if(!crossings[sid].ae or visited[sid])continue;
            if(rc>=16)return -1;var ring=rings[rc];ring.points[0]=nodes_a[start].p;ring.count=1;visited[sid]=true;var active_a=true;var index=start;var guard:usize=0;
            while(true){guard+=1;if(guard>2*xc+na+nb+1)return -1;const count=if(active_a)ca else cb;const next=(index+1)%count;const node=if(active_a)nodes_a[next] else nodes_b[next];
                if(node.crossing>=0){const id:usize=@intCast(node.crossing);visited[id]=true;if(active_a and id==sid)break;const exits=if(active_a)crossings[id].ax else crossings[id].bx;if(exits){if(id==sid)break;active_a=!active_a;index=if(active_a)pos_a[id] else pos_b[id];continue;}}
                if(ring.count>=48)return -1;ring.points[ring.count]=node.p;ring.count+=1;index=next;}
            if(ring.count<3)return -1;rings[rc]=ring;rc+=1;}
        for(0..xc)|id|if(!visited[id]){return -1;};
    }
    canonicalize(&rings,rc);var words:[WORDS]i64=@splat(0);var wc:usize=0;words[wc]=@intCast(rc);wc+=1;
    for(0..rc)|r|{words[wc]=@intCast(rings[r].count);wc+=1;for(0..rings[r].count)|i|{const p=rings[r].points[i];words[wc]=p.xn;words[wc+1]=p.xd;words[wc+2]=p.yn;words[wc+3]=p.yd;wc+=4;}}
    const bytes=wc*8;if(bytes>1680)return -1;if(output_opt==null or capacity<bytes)return -2;const output=output_opt.?;
    for(0..wc)|i|store(output,8*i,words[i]);return @intCast(bytes);
}
export fn weiler_atherton_polygon_intersection(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize) i64 {
    return runWeiler(input_opt,length,output_opt,capacity);
}
