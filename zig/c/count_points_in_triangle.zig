const MAX_N: usize = 24;
const MAX_M: usize = 24;
const MAX_Q: usize = 128;
const INPUT_MAX: usize = 483;
const BIT_STRIDE: usize = MAX_M + 1;
const Point = struct { x: i64, y: i64 };
const Vector = struct { x: i64, y: i64 };
const Query = struct { a: i64, b: i64, c: i64 };

fn half(v: Vector) i32 { if (v.y < 0) return 0; if (v.y == 0 and v.x >= 0) return 1; return 2; }
fn angleLess(a: Vector, b: Vector) bool {
    const ha = half(a); const hb = half(b);
    if (ha != hb) return ha < hb;
    return a.x * b.y - a.y * b.x > 0;
}
fn directionLess(a: Vector, b: Vector) bool {
    if (angleLess(a,b)) return true;
    if (angleLess(b,a)) return false;
    const ra = a.x*a.x+a.y*a.y; const rb = b.x*b.x+b.y*b.y;
    if (ra != rb) return ra < rb;
    if (a.x != b.x) return a.x < b.x;
    return a.y < b.y;
}
fn lowerRay(dirs: []const Vector, ray: Vector) usize {
    var low: usize = 0; var high = dirs.len;
    while (low < high) { const mid = low+(high-low)/2; if (angleLess(dirs[mid],ray)) low=mid+1 else high=mid; }
    return low;
}
fn upperRay(dirs: []const Vector, ray: Vector) usize {
    var low: usize = 0; var high = dirs.len;
    while (low < high) { const mid = low+(high-low)/2; if (!angleLess(ray,dirs[mid])) low=mid+1 else high=mid; }
    return low;
}
fn fenwickPrefix(tree: []const i32, end_value: usize) i32 {
    var end = end_value; var total: i32 = 0;
    while (end > 0) { total += tree[end]; end &= end-1; }
    return total;
}
fn arcCount(dirs: []const Vector, tree: []const i32, start: Vector, end: Vector) i32 {
    const left = lowerRay(dirs,start); const right = upperRay(dirs,end);
    if (!angleLess(end,start)) return fenwickPrefix(tree,right)-fenwickPrefix(tree,left);
    return fenwickPrefix(tree,dirs.len)-fenwickPrefix(tree,left)+fenwickPrefix(tree,right);
}
fn halfplaneCount(u: usize, v: usize, a: []const Point, dirs: []const Vector,
    counts: []const usize, zeros: []const i32, bit: []const i32) i32 {
    const edge = Vector{ .x = a[v].x-a[u].x, .y = a[v].y-a[u].y };
    const dir_base = u*MAX_M; const bit_base = u*BIT_STRIDE;
    return zeros[u] + arcCount(dirs[dir_base..dir_base+counts[u]],bit[bit_base..bit_base+counts[u]+1],Vector{ .x = -edge.x, .y = -edge.y },edge);
}
fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset+byte]=@truncate(bits>>@intCast(8*byte));
}

export fn count_points_in_triangle(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 3 or length > INPUT_MAX) return -1;
    const nr=input[0]; const mr=input[1]; const qr=input[2];
    if (nr<1 or nr>@as(i64,@intCast(MAX_N)) or mr<1 or mr>@as(i64,@intCast(MAX_M)) or qr<1 or qr>@as(i64,@intCast(MAX_Q))) return -1;
    const n: usize=@intCast(nr); const m: usize=@intCast(mr); const q: usize=@intCast(qr);
    if (length != 3+2*n+2*m+3*q) return -1;
    var a=[_]Point{.{.x=0,.y=0}}**MAX_N;
    var b=[_]Point{.{.x=0,.y=0}}**MAX_M;
    var queries=[_]Query{.{.a=0,.b=0,.c=0}}**MAX_Q;
    var cursor: usize=3;
    for (0..n) |i| { a[i]=.{.x=input[cursor],.y=input[cursor+1]}; cursor+=2; if (a[i].x < -1_000_000_000 or a[i].x > 1_000_000_000 or a[i].y < -1_000_000_000 or a[i].y > 1_000_000_000) return -1; }
    for (0..m) |i| { b[i]=.{.x=input[cursor],.y=input[cursor+1]}; cursor+=2; if (b[i].x < -1_000_000_000 or b[i].x > 1_000_000_000 or b[i].y < -1_000_000_000 or b[i].y > 1_000_000_000) return -1; }
    for (0..q) |i| { const ia=input[cursor]; const ib=input[cursor+1]; const ic=input[cursor+2]; cursor+=3; if (ia<0 or ia>=nr or ib<0 or ib>=nr or ic<0 or ic>=nr) return -1; queries[i]=.{.a=ia,.b=ib,.c=ic}; }
    const required=8*q; const output=output_opt orelse return -2; if (capacity<required) return -2;
    var dirs=[_]Vector{.{.x=0,.y=0}}**(MAX_N*MAX_M);
    var counts=[_]usize{0}**MAX_N;
    var zeros=[_]i32{0}**MAX_N;
    var bit=[_]i32{0}**(MAX_N*BIT_STRIDE);
    for (0..n) |u| {
        for (0..m) |j| { const v=Vector{.x=b[j].x-a[u].x,.y=b[j].y-a[u].y}; if(v.x==0 and v.y==0){zeros[u]+=1;}else{dirs[u*MAX_M+counts[u]]=v;counts[u]+=1;} }
        const base=u*MAX_M;
        for (1..counts[u]) |i| { const item=dirs[base+i];var j=i;while(j>0 and directionLess(item,dirs[base+j-1])):(j-=1){dirs[base+j]=dirs[base+j-1];}dirs[base+j]=item; }
        const bit_base=u*BIT_STRIDE;
        for (0..counts[u]) |i| { var at=i+1;while(at<=counts[u]){bit[bit_base+at]+=1;at+=at&(~at+1);} }
    }
    var answers=[_]i64{0}**MAX_Q;
    for (0..q) |qi| {
        const ia:usize=@intCast(queries[qi].a);var ib:usize=@intCast(queries[qi].b);var ic:usize=@intCast(queries[qi].c);
        const orient=(a[ib].x-a[ia].x)*(a[ic].y-a[ia].y)-(a[ib].y-a[ia].y)*(a[ic].x-a[ia].x);
        if(orient==0){answers[qi]=0;continue;}if(orient<0){const temp=ib;ib=ic;ic=temp;}
        const av=a[0..n];const dv=dirs[0..];const cv=counts[0..n];const zv=zeros[0..n];const fv=bit[0..];
        const outside=halfplaneCount(ia,ib,av,dv,cv,zv,fv)+halfplaneCount(ib,ic,av,dv,cv,zv,fv)+halfplaneCount(ic,ia,av,dv,cv,zv,fv);
        const bb=ib*MAX_M;const cb=ic*MAX_M;const ab=ia*MAX_M;const bt=ib*BIT_STRIDE;const ct=ic*BIT_STRIDE;const at=ia*BIT_STRIDE;
        const pairs=zeros[ib]+arcCount(dirs[bb..bb+counts[ib]],bit[bt..bt+counts[ib]+1],.{.x=a[ib].x-a[ic].x,.y=a[ib].y-a[ic].y},.{.x=a[ib].x-a[ia].x,.y=a[ib].y-a[ia].y})
          +zeros[ic]+arcCount(dirs[cb..cb+counts[ic]],bit[ct..ct+counts[ic]+1],.{.x=a[ic].x-a[ia].x,.y=a[ic].y-a[ia].y},.{.x=a[ic].x-a[ib].x,.y=a[ic].y-a[ib].y})
          +zeros[ia]+arcCount(dirs[ab..ab+counts[ia]],bit[at..at+counts[ia]+1],.{.x=a[ia].x-a[ib].x,.y=a[ia].y-a[ib].y},.{.x=a[ia].x-a[ic].x,.y=a[ia].y-a[ic].y});
        answers[qi]=@as(i64,@intCast(m))-@as(i64,outside)+@as(i64,pairs);
    }
    for(0..q)|i|storeLe(output,8*i,answers[i]);
    return @intCast(required);
}
