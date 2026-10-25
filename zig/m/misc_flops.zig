const INVALID_RESULT: f64 = -1.0e300;
const A1: f64 = -0.1666666666671334;
const A2: f64 = 0.833333333809067e-2;
const A3: f64 = 0.198412715551283e-3;
const A4: f64 = 0.27557589750762e-5;
const A5: f64 = 0.2507059876207e-7;
const A6: f64 = 0.164105986683e-9;
const B1: f64 = -0.4999999999982;
const B2: f64 = 0.4166666664651e-1;
const B3: f64 = -0.1388888805755e-2;
const B4: f64 = 0.24801428034e-4;
const B5: f64 = -0.2754213324e-6;
const B6: f64 = 0.20189405e-8;
const D1: f64 = 0.3999999946405e-1;
const D2: f64 = 0.96e-3;
const D3: f64 = 0.1233153e-5;
const E2: f64 = 0.48e-3;
const E3: f64 = 0.411051e-6;

fn sinPolyLegacy(w: f64) f64 {
    var value: f64 = A6;
    value = value*w+A5;
    value = value*w+A4;
    value = value*w+A3;
    value = value*w+A2;
    value = value*w+A1;
    return value*w+1.0;
}
fn sinPolyAlternating(w: f64) f64 {
    var value: f64 = A6;
    value = value*w-A5;
    value = value*w+A4;
    value = value*w-A3;
    value = value*w+A2;
    value = value*w+A1;
    return value*w+1.0;
}
fn cosPoly(w: f64) f64 {
    var value: f64 = B6;
    value = value*w+B5;
    value = value*w+B4;
    value = value*w+B3;
    value = value*w+B2;
    value = value*w+B1;
    return value*w+1.0;
}

export fn misc_flops(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const module_id = values[0];
    const steps = values[1];
    if (module_id < 1 or module_id > 8 or steps < 2 or steps > 128) return INVALID_RESULT;
    const pi: f64 = 3.14159265358979323846;
    const count: usize = @intCast(steps);
    var sum: f64 = 0.0;
    var result: f64 = 0.0;
    var x: f64 = 0.0;
    var u: f64 = 0.0;
    var w: f64 = 0.0;
    if (module_id == 1) {
        const n = 2 * steps;
        const dx = 1.0 / @as(f64, @floatFromInt(n));
        var v: f64 = 0.0;
        for (1..@intCast(n)) |_| {
            v += 1.0;
            u = v*dx;
            sum += (D1+u*(D2+u*D3))/(1.0+u*(D1+u*(E2+u*E3)));
        }
        const endpoint = (D1+D2+D3)/(1.0+D1+E2+E3);
        result = 1.0/(dx*(endpoint+D1+2.0*sum)/2.0);
    } else if (module_id == 2) {
        var sign: f64 = -5.0;
        var partial: f64 = -1.0;
        for (0..count) |_| { sign = -sign; partial += sign; }
        var v: f64 = 0.0;
        var reciprocal_sum: f64 = 0.0;
        u = partial;
        x = 0.0;
        for (0..count) |_| {
            sign = -sign; partial += sign; u += 2.0;
            x = x+(sign-u); v = v-sign*u; reciprocal_sum = reciprocal_sum+sign/u;
        }
        const estimate = 4.0*reciprocal_sum/5.0+5.0/v;
        result = estimate-31.25/(v*v*v);
    } else if (module_id == 3) {
        const dx = pi/(3.0*@as(f64, @floatFromInt(count)));
        var v: f64 = 0.0;
        for (1..count) |_| { v += 1.0; u=v*dx; w=u*u; sum += u*sinPolyAlternating(w); }
        u = pi/3.0; w=u*u;
        result = dx*(u*sinPolyAlternating(w)+2.0*sum)/2.0;
    } else if (module_id == 4) {
        const dx = pi/(3.0*@as(f64, @floatFromInt(count)));
        for (1..count) |i| { u=@as(f64, @floatFromInt(i))*dx; w=u*u; sum += w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0; }
        u=pi/3.0; w=u*u;
        const endpoint = w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0;
        result = dx*(endpoint+1.0+2.0*sum)/2.0;
    } else if (module_id == 5) {
        const dx = pi/(3.0*@as(f64, @floatFromInt(count)));
        for (1..count) |i| { u=@as(f64, @floatFromInt(i))*dx; w=u*u; sum += (u*sinPolyLegacy(w))/cosPoly(w); }
        u=pi/3.0; w=u*u;
        result=dx*(u*sinPolyLegacy(w)/cosPoly(w)+2.0*sum)/2.0;
    } else if (module_id == 6) {
        const dx = pi/(4.0*@as(f64, @floatFromInt(count)));
        for (1..count) |i| { u=@as(f64, @floatFromInt(i))*dx; w=u*u; sum += (u*sinPolyLegacy(w))*cosPoly(w); }
        u=pi/4.0; w=u*u;
        result=dx*((u*sinPolyLegacy(w))*cosPoly(w)+2.0*sum)/2.0;
    } else if (module_id == 7) {
        const finish: f64 = 102.3321513995275;
        const dx = finish/@as(f64, @floatFromInt(count));
        for (1..count) |i| { x=@as(f64, @floatFromInt(i))*dx; u=x*x; sum=sum-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0); }
        x=finish; u=x*x;
        const endpoint=-1.0-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0);
        result=18.0*dx*(endpoint+2.0*sum);
    } else {
        const dx = pi/(3.0*@as(f64, @floatFromInt(count)));
        for (1..count) |i| { u=@as(f64, @floatFromInt(i))*dx; w=u*u; const cosine=cosPoly(w); sum += cosine*cosine*u*sinPolyLegacy(w); }
        u=pi/3.0; w=u*u; const cosine=cosPoly(w);
        result=dx*((u*sinPolyLegacy(w))*cosine*cosine+2.0*sum)/2.0;
    }
    return result;
}
