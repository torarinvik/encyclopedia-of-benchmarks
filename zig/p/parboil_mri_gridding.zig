const CELLS: usize = 27;
const MAX_SAMPLES: i64 = 4;
const WIDTH: f32 = 2.5;
const OVERSAMPLE: f32 = 0.608933;
const COEFF = [_]f32{
    0.210580722890567e-22, 0.380715242345326e-19, 0.479440257548300e-16,
    0.435125971262668e-13, 0.300931127112960e-10, 0.160224679395361e-7,
    0.654858370096785e-5, 0.202591084143397e-2, 0.463076284721000e0,
    0.754337328948189e2, 0.830792541809429e4, 0.571661130563785e6,
    0.216415572361227e8, 0.356644482244025e9, 0.144048298227235e10,
};

fn decode(raw: i64) f32 { return @as(f32, @floatFromInt(raw)) / 1_000_000.0; }
fn kernel(value: f32) f32 {
    const z = value * value;
    var num = COEFF[0];
    for (1..15) |i| { const product = z * num; num = product + COEFF[i]; }
    var den = z - @as(f32, 0.307646912682801e4);
    den = z * den; den = den + @as(f32, 0.347626332405882e7);
    den = z * den; den = den - @as(f32, 0.144048298227235e10);
    return -num / den;
}
fn betaValue() f32 {
    var first: f32 = 4.0 * WIDTH; first = first * WIDTH;
    const divisor = OVERSAMPLE * OVERSAMPLE; first = first / divisor;
    const shifted = @as(f64, OVERSAMPLE) - 0.5;
    var argument = @as(f64, first) * shifted; argument = argument * shifted; argument = argument - 0.8;
    return @floatCast(3.14159265359 * @sqrt(argument));
}
fn weight(v: f32, inverse: f32, beta: f32, sdc: f32) f32 {
    const product = v * inverse;
    const radicand = 1.0 - @as(f64, product);
    const argument: f32 = @floatCast(@as(f64, beta) * @sqrt(radicand));
    return kernel(argument) * sdc;
}
fn lower(k: f32, cutoff: f32) usize {
    const delta = k - cutoff;
    if (delta < 0) return 0;
    return @intFromFloat(delta);
}
fn upper(k: f32, cutoff: f32) usize {
    const total = k + cutoff;
    if (total > 2) return 2;
    return @intFromFloat(total);
}
fn quantize(value: f32) i64 {
    const scaled = value * 1000.0;
    const magnitude = if (scaled < 0) -scaled else scaled;
    var whole: i64 = @intFromFloat(magnitude);
    if (magnitude - @as(f32, @floatFromInt(whole)) >= 0.5) whole += 1;
    return if (scaled < 0) -whole else whole;
}

export fn parboil_mri_gridding(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 25) return -1;
    const n = input[0];
    if (n < 0 or n > MAX_SAMPLES or length != 1 + 6 * @as(usize, @intCast(n))) return -1;
    const sample_count: usize = @intCast(n);
    for (0..sample_count) |s| {
        const p = 1 + 6*s;
        for (0..3) |axis| {
            if (input[p+axis] != 0 and input[p+axis] != 1_000_000 and input[p+axis] != 2_000_000) return -1;
        }
        if (input[p+3] < -1_000_000 or input[p+3] > 1_000_000 or input[p+4] < -1_000_000 or input[p+4] > 1_000_000 or input[p+5] < 0 or input[p+5] > 1_000_000) return -1;
    }
    var real = [_]f32{0} ** CELLS;
    var imag = [_]f32{0} ** CELLS;
    var density = [_]f32{0} ** CELLS;
    const cutoff: f32 = @floatCast(@as(f64, WIDTH) / 2.0);
    const cutoff2 = cutoff * cutoff;
    const inverse: f32 = 1.0 / cutoff2;
    const beta = betaValue();
    for (0..sample_count) |s| {
        const p = 1 + 6*s;
        const kx=decode(input[p]); const ky=decode(input[p+1]); const kz=decode(input[p+2]);
        const sr=decode(input[p+3]); const si=decode(input[p+4]); const sdc=decode(input[p+5]);
        if ((sr != 0 or si != 0) and sdc != 0) {
            const x0=lower(kx,cutoff); const x1=upper(kx,cutoff);
            const y0=lower(ky,cutoff); const y1=upper(ky,cutoff);
            const z0=lower(kz,cutoff); const z1=upper(kz,cutoff);
            for (z0..z1+1) |z| {
                const dz=kz-@as(f32,@floatFromInt(z)); const dz2=dz*dz;
                if (dz2 < cutoff2) {
                    for (y0..y1+1) |y| {
                        const dy=ky-@as(f32,@floatFromInt(y)); const dy2=dy*dy; const yz=dz2+dy2;
                        if (yz < cutoff2) {
                            for (x0..x1+1) |x| {
                                const dx=kx-@as(f32,@floatFromInt(x)); const dx2=dx*dx; const v=yz+dx2;
                                if (v < cutoff2) {
                                    const index=x+3*y+9*z; const w=weight(v,inverse,beta,sdc);
                                    const dr=w*sr; const di=w*si;
                                    real[index]=real[index]+dr; imag[index]=imag[index]+di;
                                    density[index]=@floatCast(@as(f64,density[index])+1.0);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    var checksum: i64 = 0;
    for (0..CELLS) |i| checksum += @as(i64,@intCast(i+1))*(quantize(real[i])+quantize(imag[i])+@as(i64,@intFromFloat(density[i])));
    return checksum;
}
