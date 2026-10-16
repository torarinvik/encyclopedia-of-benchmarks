const C = struct { r: f64, i: f64 };
fn sub(a: C, b: C) C { return .{ .r=a.r-b.r, .i=a.i-b.i }; }
fn mul(a: C, b: C) C { return .{ .r=a.r*b.r-a.i*b.i, .i=a.r*b.i+a.i*b.r }; }
fn div(a: C, b: C) C {
    const den=b.r*b.r+b.i*b.i;
    return .{ .r=(a.r*b.r+a.i*b.i)/den, .i=(a.i*b.r-a.r*b.i)/den };
}
fn magnitude(a: C) f64 { return @sqrt(a.r*a.r+a.i*a.i); }

export fn durand_kerner_roots(v: [*c]const i64, n: usize) f64 {
    if (v == null or n != 3) return -1.0e300;
    const d=v[0]; const ri=v[1]; const part=v[2];
    if (d == 0 or d < -4 or d > 4 or ri < 0 or ri > 2 or part < 0 or part > 1) return -1.0e300;
    const s: f64=if (d>0) 1.0 else -1.0;
    const q=@sqrt(3.0)/2.0;
    var z=[_]C{.{.r=s,.i=0},.{.r=-0.5*s,.i=q*s},.{.r=-0.5*s,.i=-q*s}};
    for (0..100) |_| {
        var next=z; var change: f64=0;
        for (0..3) |i| {
            var den=C{.r=1,.i=0};
            for (0..3) |j| { if (i!=j) den=mul(den,sub(z[i],z[j])); }
            const z3=mul(mul(z[i],z[i]),z[i]);
            next[i]=sub(z[i],div(sub(z3,C{.r=@floatFromInt(d),.i=0}),den));
            change=@max(change,magnitude(sub(next[i],z[i])));
        }
        z=next;
        if (change < 1.0e-14) break;
    }
    return if (part==0) z[@intCast(ri)].r else z[@intCast(ri)].i;
}
