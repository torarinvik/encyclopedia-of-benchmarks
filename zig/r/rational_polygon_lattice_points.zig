fn rplFloorDiv(a: i64, b: i64) i64 { return @divFloor(a, b); }
fn rplCeilDiv(a: i64, b: i64) i64 { return -rplFloorDiv(-a, b); }

fn rplFloorSum(n0: i64, m0: i64, a0: i64, b0: i64) i64 {
    const aq = rplFloorDiv(a0, m0);
    const bq = rplFloorDiv(b0, m0);
    var answer = @divTrunc(aq*n0*(n0-1),2)+bq*n0;
    var a = a0-aq*m0;
    var b = b0-bq*m0;
    var n = n0;
    var m = m0;
    while (true) {
        if (a >= m) { answer += @divTrunc((n-1)*n*@divTrunc(a,m),2); a = @rem(a,m); }
        if (b >= m) { answer += n*@divTrunc(b,m); b = @rem(b,m); }
        const top = a*n+b;
        if (top < m) return answer;
        n = @divTrunc(top,m);
        b = @rem(top,m);
        const t = m;
        m = a;
        a = t;
    }
}

fn rplEdgeChunk(scale: i64, ax: i64, ay: i64, dx: i64, dy: i64,
                start: i64, columns: i64) i64 {
    if (columns <= 0) return 0;
    var aa=dy*scale;
    var bb=ay*dx-dy*ax;
    var den=scale*dx;
    if (den < 0) { aa=-aa; bb=-bb; den=-den; }
    const base=aa*start+bb;
    if (dx > 0) return -rplFloorSum(columns,den,aa,base);
    return -rplFloorSum(columns,den,-aa,-base)-columns;
}

fn rplInside(xs: [8]i64, ys: [8]i64, n: usize, scale: i64, x: i64, y: i64) bool {
    const px=x*scale;
    const py=y*scale;
    var inside=false;
    for (0..n) |i| {
        const j=(i+1)%n;
        const cross=(xs[j]-xs[i])*(py-ys[i])-(ys[j]-ys[i])*(px-xs[i]);
        if (cross==0 and px>=@min(xs[i],xs[j]) and px<=@max(xs[i],xs[j]) and py>=@min(ys[i],ys[j]) and py<=@max(ys[i],ys[j])) return false;
        if ((ys[i]>py)!=(ys[j]>py)) {
            const dy=ys[j]-ys[i];
            const dx=xs[j]-xs[i];
            const left=xs[i]*dy+(py-ys[i])*dx;
            const right=px*dy;
            if ((dy>0 and left>right) or (dy<0 and left<right)) inside=!inside;
        }
    }
    return inside;
}

pub export fn rational_polygon_lattice_points(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 19) return -1;
    const input = input_opt.?;
    const scale = input[0];
    const nr = input[1];
    if (scale < 2 or scale > 8 or nr < 3 or nr > 8 or length != @as(usize, @intCast(2+2*nr))) return -1;
    const n: usize = @intCast(nr);
    var xs = [_]i64{0} ** 8;
    var ys = [_]i64{0} ** 8;
    var fractional = false;
    for (0..n) |i| {
        xs[i] = input[2+2*i];
        ys[i] = input[3+2*i];
        if (xs[i] < -32 or xs[i] > 32 or ys[i] < -32 or ys[i] > 32) return -1;
        if (xs[i] < -4*scale or xs[i] > 4*scale or ys[i] < -4*scale or ys[i] > 4*scale) return -1;
        if (@rem(xs[i],scale) != 0 or @rem(ys[i],scale) != 0) fractional = true;
        for (0..i) |j| { if (xs[i] == xs[j] and ys[i] == ys[j]) return -1; }
    }
    if (!fractional) return -1;
    var area2: i64 = 0;
    for (0..n) |i| {
        const j = (i+1)%n;
        area2 += xs[i]*ys[j]-ys[i]*xs[j];
    }
    if (area2 == 0) return -1;
    const orientation: i64 = if (area2 > 0) 1 else -1;
    for (0..n) |i| {
        const next = (i+1)%n;
        for (0..n) |j| {
            if (j == i or j == next) continue;
            const cross = (xs[next]-xs[i])*(ys[j]-ys[i])-(ys[next]-ys[i])*(xs[j]-xs[i]);
            if (cross*orientation <= 0) return -1;
        }
    }
    var signed_count: i64 = 0;
    for (0..n) |i| {
        const j = (i+1)%n;
        const dx = xs[j]-xs[i];
        const dy = ys[j]-ys[i];
        if (dx == 0) continue;
        const lo = @min(xs[i],xs[j]);
        const hi = @max(xs[i],xs[j]);
        const start = rplCeilDiv(lo,scale);
        const stop = rplCeilDiv(hi,scale);
        var cursor=start;
        var col=start;
        while (col<stop) : (col+=1) {
            var event=false;
            for (0..n) |k| { if (xs[k]==col*scale) event=true; }
            if (event) {
                signed_count += rplEdgeChunk(scale,xs[i],ys[i],dx,dy,cursor,col-cursor);
                cursor=col+1;
            }
        }
        signed_count += rplEdgeChunk(scale,xs[i],ys[i],dx,dy,cursor,stop-cursor);
    }
    for (0..n) |i| {
        if (@rem(xs[i],scale)!=0) continue;
        var first=true;
        for (0..i) |j| { if (xs[j]==xs[i]) first=false; }
        if (!first) continue;
        const x=@divTrunc(xs[i],scale);
        var count: i64=0;
        var y: i64=-4;
        while (y<=4) : (y+=1) { if (rplInside(xs,ys,n,scale,x,y)) count+=1; }
        signed_count += orientation*count;
    }
    const result = signed_count*orientation;
    return if (result >= 0) result else -1;
}
