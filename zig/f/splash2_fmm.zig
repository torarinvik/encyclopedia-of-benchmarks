const MAX_PARTICLES: usize = 48;
const BOXES: usize = 16;
const ORDER: usize = 32;
const STRIDE: usize = ORDER + 1;

export fn splash2_fmm(input: [*c]const f64, input_length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length < 7 or input_length > 145) return -1;
    const requested = input[0];
    if (requested != requested or requested < 2.0 or requested > 48.0 or
        @as(f64, @floatFromInt(@as(usize, @intFromFloat(requested)))) != requested) return -1;
    const n: usize = @intFromFloat(requested);
    if (input_length != 1 + 3*n) return -1;
    var x: [MAX_PARTICLES]f64 = undefined;
    var y: [MAX_PARTICLES]f64 = undefined;
    var charge: [MAX_PARTICLES]f64 = undefined;
    var box: [MAX_PARTICLES]usize = undefined;
    for (0..n) |i| {
        const px = input[1+3*i]; const py = input[2+3*i]; const q = input[3+3*i];
        if (px != px or px < 0.0 or px >= 8.0 or
            @as(f64, @floatFromInt(@as(usize, @intFromFloat(px)))) != px or
            py != py or py < 0.0 or py >= 8.0 or
            @as(f64, @floatFromInt(@as(usize, @intFromFloat(py)))) != py or
            q != q or q < -3.0 or q > 3.0 or
            @as(f64, @floatFromInt(@as(i32, @intFromFloat(q)))) != q) return -1;
        x[i] = px; y[i] = py; charge[i] = q;
        box[i] = (@as(usize, @intFromFloat(py)) / 2) * 4 + @as(usize, @intFromFloat(px)) / 2;
        for (0..i) |j| if (x[i] == x[j] and y[i] == y[j]) return -1;
    }
    if (output == null or output_capacity < n) return -2;
    var mr: [BOXES][STRIDE]f64 = undefined;
    var mi: [BOXES][STRIDE]f64 = undefined;
    var lr: [BOXES][STRIDE]f64 = undefined;
    var li: [BOXES][STRIDE]f64 = undefined;
    for (0..BOXES) |b| {
        for (0..STRIDE) |k| {
            mr[b][k] = 0.0; mi[b][k] = 0.0; lr[b][k] = 0.0; li[b][k] = 0.0;
        }
    }
    for (0..n) |i| {
        const b = box[i];
        const zr = x[i] - @as(f64, @floatFromInt(2 * (b % 4) + 1));
        const zi = y[i] - @as(f64, @floatFromInt(2 * (b / 4) + 1));
        var pr: f64 = 1.0; var pi: f64 = 0.0;
        mr[b][0] += charge[i];
        for (1..ORDER+1) |k| {
            const nr = pr*zr - pi*zi; const ni = pr*zi + pi*zr;
            pr = nr; pi = ni;
            mr[b][k] += charge[i]*pr; mi[b][k] += charge[i]*pi;
        }
    }
    for (0..BOXES) |target| {
        const tx: i32 = @intCast(target % 4); const ty: i32 = @intCast(target / 4);
        for (0..BOXES) |source| {
            const sx: i32 = @intCast(source % 4); const sy: i32 = @intCast(source / 4);
            const dbx = tx-sx; const dby = ty-sy;
            if (dbx >= -1 and dbx <= 1 and dby >= -1 and dby <= 1) continue;
            const dx = 2.0 * @as(f64, @floatFromInt(dbx));
            const dy = 2.0 * @as(f64, @floatFromInt(dby));
            const r2 = dx*dx + dy*dy;
            var ir: [2*ORDER+1]f64 = undefined; var ii: [2*ORDER+1]f64 = undefined;
            ir[0] = 1.0; ii[0] = 0.0;
            const odr = dx/r2; const odi = -dy/r2;
            for (1..2*ORDER+1) |p| {
                ir[p] = ir[p-1]*odr - ii[p-1]*odi;
                ii[p] = ir[p-1]*odi + ii[p-1]*odr;
            }
            var constant = mr[source][0]*0.5*@log(r2);
            for (1..ORDER+1) |k|
                constant -= (mr[source][k]*ir[k] - mi[source][k]*ii[k]) / @as(f64, @floatFromInt(k));
            lr[target][0] += constant;
            for (1..ORDER+1) |order| {
                var sr: f64 = 0.0; var si: f64 = 0.0;
                for (1..ORDER+1) |k| {
                    var choose: f64 = 1.0;
                    for (1..order+1) |j|
                        choose *= @as(f64, @floatFromInt(k+j-1)) / @as(f64, @floatFromInt(j));
                    const scale = choose / @as(f64, @floatFromInt(k));
                    const p = k + order;
                    sr += scale*(mr[source][k]*ir[p] - mi[source][k]*ii[p]);
                    si += scale*(mr[source][k]*ii[p] + mi[source][k]*ir[p]);
                }
                const qsign: f64 = if (order % 2 == 1) 1.0 else -1.0;
                const msign: f64 = if (order % 2 == 1) -1.0 else 1.0;
                const divisor: f64 = @floatFromInt(order);
                lr[target][order] += mr[source][0]*(qsign/divisor)*ir[order] - msign*sr;
                li[target][order] += mr[source][0]*(qsign/divisor)*ii[order] - msign*si;
            }
        }
    }
    for (0..n) |i| {
        const b = box[i]; const bx: i32 = @intCast(b % 4); const by: i32 = @intCast(b / 4);
        const wr = x[i] - @as(f64, @floatFromInt(2*@as(usize, @intCast(bx))+1));
        const wi = y[i] - @as(f64, @floatFromInt(2*@as(usize, @intCast(by))+1));
        var pr: f64 = 1.0; var pi: f64 = 0.0; var value = lr[b][0];
        for (1..ORDER+1) |order| {
            const nr = pr*wr - pi*wi; const ni = pr*wi + pi*wr;
            pr = nr; pi = ni;
            value += lr[b][order]*pr - li[b][order]*pi;
        }
        for (0..n) |j| {
            if (j == i) continue;
            const sb = box[j]; const sx: i32 = @intCast(sb % 4); const sy: i32 = @intCast(sb / 4);
            const dbx = bx-sx; const dby = by-sy;
            if (dbx < -1 or dbx > 1 or dby < -1 or dby > 1) continue;
            const dx = x[j]-x[i]; const dy = y[j]-y[i];
            value += charge[j]*0.5*@log(dx*dx+dy*dy);
        }
        output[i] = value;
    }
    return @intCast(n);
}
