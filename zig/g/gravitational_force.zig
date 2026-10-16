export fn gravitational_force(v: [*c]const f64, n: usize, output: [*c]f64, capacity: usize) i64 {
    if (v == null or n != 6) return -1;
    for (0..6) |i| if (v[i] != v[i] or v[i] > 1.0e100 or v[i] < -1.0e100) return -1;
    const m1,x1,y1,m2,x2,y2 = .{v[0],v[1],v[2],v[3],v[4],v[5]};
    if (@abs(m1)>1.0e12 or @abs(m2)>1.0e12 or (m1!=0.0 and @abs(m1)<1.0e-12) or
        (m2!=0.0 and @abs(m2)<1.0e-12) or @abs(x1)>1.0e6 or @abs(y1)>1.0e6 or @abs(x2)>1.0e6 or @abs(y2)>1.0e6) return -1;
    const dx=x1-x2; const dy=y1-y2; const d2=dx*dx+dy*dy;
    if (d2!=0.0 and d2<1.0e-12) return -1;
    if (output==null or capacity<2) return -2;
    if (d2==0.0) { output[0]=0.0; output[1]=0.0; return 2; }
    const distance=@sqrt(d2); const magnitude=6.67430e-11*m1*m2/d2;
    output[0]=magnitude*(dx/distance); output[1]=magnitude*(dy/distance);
    return 2;
}
