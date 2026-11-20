const min_n: usize = 3;
const max_n: usize = 5;
const max_length: usize = 12;
const dp_size: usize = 10;
const dp_cells: usize = dp_size * dp_size;

const Point = struct { x: i64 = 0, y: i64 = 0 };
const Score = struct { num: i64 = 0, den: i64 = 1 };
const Cell = struct { minimum: Score = .{}, count: i32 = 0, valid: bool = false, split: i32 = -1 };
const Triangle = struct { a: usize = 0, b: usize = 0, c: usize = 0 };
const Triangles = struct { items: [3]Triangle = [_]Triangle{.{}} ** 3, count: usize = 0 };
const Objective = struct { minimum: Score, count: i32 };

fn orient(a: Point, b: Point, c: Point) i64 {
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
}
fn abs64(value: i64) i64 { return if (value < 0) -value else value; }
fn gcd64(a0: i64, b0: i64) i64 {
    var a = a0; var b = b0;
    while (b != 0) { const r = @rem(a,b); a=b; b=r; }
    return a;
}
fn fraction(num: i64, den: i64) Score {
    const divisor = gcd64(num,den);
    return .{ .num=num/divisor, .den=den/divisor };
}
fn compare(a: Score, b: Score) i32 {
    const left=a.num*b.den; const right=b.num*a.den;
    return if (left<right) -1 else if (left>right) 1 else 0;
}
fn triangleScore(points: *const [max_n]Point, n: usize, a: usize, b: usize, c: usize) Score {
    const p=points[a%n]; const q=points[b%n]; const r=points[c%n];
    const area=abs64(orient(p,q,r));
    const lengths=[_]i64{
        (p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y),
        (q.x-r.x)*(q.x-r.x)+(q.y-r.y)*(q.y-r.y),
        (r.x-p.x)*(r.x-p.x)+(r.y-p.y)*(r.y-p.y),
    };
    var best=fraction(area*area,lengths[0]);
    for (lengths[1..]) |den| {
        const candidate=fraction(area*area,den);
        if (compare(candidate,best)<0) best=candidate;
    }
    return best;
}
fn join(left: Cell, right: Cell, triangle: Score) Objective {
    var out=Objective{ .minimum=triangle, .count=1 };
    const children=[_]Cell{left,right};
    for (children) |child| {
        if (!child.valid) continue;
        const cmp=compare(child.minimum,out.minimum);
        if (cmp<0) { out.minimum=child.minimum; out.count=child.count; }
        else if (cmp==0) out.count+=child.count;
    }
    return out;
}
fn better(candidate: Objective, current: Objective) bool {
    const cmp=compare(candidate.minimum,current.minimum);
    return cmp>0 or (cmp==0 and candidate.count<current.count);
}
fn evaluate(points: *const [max_n]Point, n: usize, triangles: Triangles) Objective {
    const first=triangles.items[0];
    var out=Objective{ .minimum=triangleScore(points,n,first.a,first.b,first.c), .count=1 };
    for (triangles.items[1..triangles.count]) |t| {
        const score=triangleScore(points,n,t.a,t.b,t.c);
        const cmp=compare(score,out.minimum);
        if (cmp<0) { out.minimum=score; out.count=1; }
        else if (cmp==0) out.count+=1;
    }
    return out;
}
fn collect(start: usize, end: usize, table: *const [dp_cells]Cell, n: usize, out: *Triangles) void {
    if (end-start<2) return;
    const middle: usize=@intCast(table[start*dp_size+end].split);
    out.items[out.count]=Triangle{ .a=start%n, .b=middle%n, .c=end%n };
    out.count+=1;
    collect(start,middle,table,n,out);
    collect(middle,end,table,n,out);
}
fn hasEdge(triangles: Triangles, left: usize, right: usize) bool {
    for (triangles.items[0..triangles.count]) |t| {
        const pairs=[_][2]usize{.{t.a,t.b},.{t.b,t.c},.{t.c,t.a}};
        for (pairs) |pair| {
            const a=@min(pair[0],pair[1]); const b=@max(pair[0],pair[1]);
            if (a==left and b==right) return true;
        }
    }
    return false;
}
fn solve(points: *const [max_n]Point, n: usize) i64 {
    const empty=Cell{};
    var table=[_]Cell{empty} ** dp_cells;
    if (n>3) {
        var span: usize=2;
        while (span<=n-2) : (span+=1) {
            var start: usize=0;
            while (start<n) : (start+=1) {
                const end=start+span;
                var found=false;
                var best=Objective{ .minimum=Score{}, .count=0 };
                var best_middle: usize=0;
                var middle=start+1;
                while (middle<end) : (middle+=1) {
                    const candidate=join(table[start*dp_size+middle],table[middle*dp_size+end],
                                         triangleScore(points,n,start,middle,end));
                    if (!found or better(candidate,best)) { found=true; best=candidate; best_middle=middle; }
                }
                table[start*dp_size+end]=Cell{ .minimum=best.minimum, .count=best.count,
                                               .valid=true, .split=@intCast(best_middle) };
            }
        }
    }
    var current=Triangles{};
    var middle: usize=1;
    while (middle<n-1) : (middle+=1) {
        current.items[current.count]=Triangle{ .a=0, .b=middle, .c=middle+1 };
        current.count+=1;
    }
    var current_value=evaluate(points,n,current);
    var improvements: usize=0;
    while (true) {
        var changed=false;
        var left: usize=0;
        while (left<n and !changed) : (left+=1) {
            var right=left+2;
            while (right<n) : (right+=1) {
                if (left==0 and right==n-1) continue;
                if (hasEdge(current,left,right)) continue;
                var candidate=Triangles{};
                collect(left,right,&table,n,&candidate);
                collect(right,left+n,&table,n,&candidate);
                const value=evaluate(points,n,candidate);
                if (better(value,current_value)) {
                    current=candidate; current_value=value; improvements+=1;
                    if (improvements>30) return -1;
                    changed=true; break;
                }
            }
        }
        if (!changed) return current_value.minimum.num*513+current_value.minimum.den;
    }
}

export fn max_min_triangle_height_triangulation(input: ?[*]const i64, length: usize) i64 {
    if (input==null or length<1 or length>max_length) return -1;
    const words=input.?;
    if (words[0]<min_n or words[0]>max_n) return -1;
    const n: usize=@intCast(words[0]);
    if (length!=1+2*n) return -1;
    var points=[_]Point{.{}} ** max_n;
    for (0..n) |i| {
        points[i]=Point{ .x=words[1+2*i], .y=words[2+2*i] };
        if (points[i].x < -8 or points[i].x > 8 or points[i].y < -8 or points[i].y > 8) return -1;
        for (0..i) |j| if (points[i].x==points[j].x and points[i].y==points[j].y) return -1;
    }
    var area2: i64=0;
    for (0..n) |i| { const next=(i+1)%n; area2+=points[i].x*points[next].y-points[i].y*points[next].x; }
    if (area2<=0) return -1;
    for (0..n) |a| for (a+1..n) |b| for (b+1..n) |c| {
        if (orient(points[a],points[b],points[c])==0) return -1;
    };
    for (0..n) |edge| {
        const next=(edge+1)%n;
        for (0..n) |v| if (v!=edge and v!=next and orient(points[edge],points[next],points[v])<=0) return -1;
    }
    return solve(&points,n);
}
