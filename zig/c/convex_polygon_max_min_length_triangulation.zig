const min_n: usize = 3;
const max_n: usize = 6;
const max_length: usize = 14;

const Point = struct { x: i64 = 0, y: i64 = 0 };

fn orient(a: Point, b: Point, c: Point) i64 {
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
}
fn distanceSquared(a: Point, b: Point) i64 {
    const dx=a.x-b.x;
    const dy=a.y-b.y;
    return dx*dx+dy*dy;
}
fn diagonalBit(n: usize, a: usize, b: usize) i32 {
    const left=@min(a,b);
    const right=@max(a,b);
    var bit: i32=0;
    for (0..n) |first| {
        var second=first+2;
        while (second<n) : (second+=1) {
            if (first==0 and second==n-1) continue;
            if (first==left and second==right) return bit;
            bit+=1;
        }
    }
    return -1;
}
fn angleAtLeastSixty(p: Point, q: Point, r: Point) bool {
    const ux=p.x-q.x;
    const uy=p.y-q.y;
    const vx=r.x-q.x;
    const vy=r.y-q.y;
    const dot=ux*vx+uy*vy;
    if (dot<=0) return true;
    const norm_u=ux*ux+uy*uy;
    const norm_v=vx*vx+vy*vy;
    return 4*dot*dot<=norm_u*norm_v;
}
fn greedy(points: *const [max_n]Point, n: usize) i64 {
    var next=[_]usize{0} ** max_n;
    for (0..n) |i| next[i]=(i+1)%n;
    var shortest: i64=513;
    for (0..n) |i| {
        const edge=distanceSquared(points[i],points[(i+1)%n]);
        if (edge<shortest) shortest=edge;
    }
    var active=n;
    var p: usize=0;
    var q=next[p];
    var r=next[q];
    var steps: usize=0;
    var diagonal_mask: i64=0;
    while (active>3) {
        steps+=1;
        if (steps>4*n) return -1;
        if (angleAtLeastSixty(points[p],points[q],points[r])) {
            const chord=distanceSquared(points[p],points[r]);
            if (chord<shortest) shortest=chord;
            const bit=diagonalBit(n,p,r);
            if (bit<0) return -1;
            diagonal_mask += @as(i64,1) << @intCast(bit);
            next[p]=r;
            active-=1;
            q=r;
            r=next[r];
        } else {
            p=q;
            q=r;
            r=next[r];
        }
    }
    return shortest*512+diagonal_mask;
}

export fn convex_polygon_max_min_length_triangulation(input: ?[*]const i64, length: usize) i64 {
    if (input==null or length<1 or length>max_length) return -1;
    const words=input.?;
    if (words[0]<min_n or words[0]>max_n) return -1;
    const n: usize=@intCast(words[0]);
    if (length!=1+2*n) return -1;
    var points=[_]Point{.{}} ** max_n;
    for (0..n) |i| {
        points[i]=Point{ .x=words[1+2*i], .y=words[2+2*i] };
        if (points[i].x < -8 or points[i].x > 8 or points[i].y < -8 or points[i].y > 8) return -1;
        for (0..i) |j| {
            if (points[i].x==points[j].x and points[i].y==points[j].y) return -1;
        }
    }
    var area2: i64=0;
    for (0..n) |i| {
        const following=(i+1)%n;
        area2+=points[i].x*points[following].y-points[i].y*points[following].x;
    }
    if (area2<=0) return -1;
    for (0..n) |a| {
        for (a+1..n) |b| {
            for (b+1..n) |c| {
                if (orient(points[a],points[b],points[c])==0) return -1;
            }
        }
    }
    for (0..n) |edge| {
        const following=(edge+1)%n;
        for (0..n) |vertex| {
            if (vertex!=edge and vertex!=following and orient(points[edge],points[following],points[vertex])<=0) return -1;
        }
    }
    return greedy(&points,n);
}
