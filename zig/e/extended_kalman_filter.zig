const bad: f64 = -1.0e300;
export fn extended_kalman_filter(v: [*c]const i64, n: usize) f64 {
    if (v == null or n < 10 or n > 17) return bad;
    const steps = v[0]; if (steps < 1 or steps > 8 or n != @as(usize, @intCast(9 + steps))) return bad;
    for (1..9) |i| { if (v[i] < -10000 or v[i] > 10000) return bad; }
    for (9..n) |i| { if (v[i] < -10000 or v[i] > 10000) return bad; }
    const sc: f64 = 1000.0;
    var x: f64 = @as(f64,@floatFromInt(v[1]))/sc; var y: f64 = @as(f64,@floatFromInt(v[2]))/sc;
    var p00: f64 = @as(f64,@floatFromInt(v[3]))/sc; var p01: f64 = @as(f64,@floatFromInt(v[4]))/sc; var p11: f64 = @as(f64,@floatFromInt(v[5]))/sc;
    const q0: f64 = @as(f64,@floatFromInt(v[6]))/sc; const q1: f64 = @as(f64,@floatFromInt(v[7]))/sc; const r: f64 = @as(f64,@floatFromInt(v[8]))/sc;
    if (v[1] < -2000 or v[1] > 2000 or v[2] < -2000 or v[2] > 2000 or p00 <= 0 or p11 <= 0 or p00*p11 <= p01*p01 or q0 < 0 or q1 < 0 or r <= 0 or r > 10) return bad;
    for (0..@intCast(steps)) |t| {
        const f01: f64=0.1; const f10: f64=0.1*x; const nx=x+f01*y; const ny=y+0.05*x*x;
        const a=p00+2*f01*p01+f01*f01*p11+q0; const b=f10*p00+(1+f01*f10)*p01+f01*p11; const c=f10*f10*p00+2*f10*p01+p11+q1;
        x=nx;y=ny;p00=a;p01=b;p11=c;
        const h0=0.1*x;const res=@as(f64,@floatFromInt(v[9+t]))/sc-(0.05*x*x+y);const s=h0*h0*p00+2*h0*p01+p11+r;if(!(s>0))return bad;
        const k0=(p00*h0+p01)/s;const k1=(p01*h0+p11)/s;x+=k0*res;y+=k1*res;
        const a00=1-k0*h0;const a01=-k0;const a10=-k1*h0;const a11=1-k1;
        const z00=a00*a00*p00+2*a00*a01*p01+a01*a01*p11+k0*k0*r;const z01=a00*a10*p00+(a00*a11+a01*a10)*p01+a01*a11*p11+k0*k1*r;const z11=a10*a10*p00+2*a10*a11*p01+a11*a11*p11+k1*k1*r;p00=z00;p01=z01;p11=z11;
    }
    return x;
}
