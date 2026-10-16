const std = @import("std");

fn putF64(out: [*]u8, offset: *usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| { out[offset.*] = @truncate(bits >> @intCast(8 * b)); offset.* += 1; }
}
fn putI64(out: [*]u8, offset: *usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| { out[offset.*] = @truncate(bits >> @intCast(8 * b)); offset.* += 1; }
}

pub export fn correlation_matrix_analysis(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 22) return -1;
    if (input[0] != 4 or input[1] < 2 or input[1] > 5) return -1;
    const p: usize = @intCast(input[1]);
    if (length != 2 + 4 * p) return -1;
    for (0..4 * p) |i| { if (input[2 + i] < -1000 or input[2 + i] > 1000) return -1; }
    for (0..p) |col| {
        var varying = false;
        for (1..4) |row| { if (input[2 + row * p + col] != input[2 + col]) varying = true; }
        if (!varying) return -1;
    }
    const output_bytes = 32 * p * p + 48;
    if (output == null or capacity < output_bytes) return -2;
    var means = [_]f64{0} ** 5;
    for (0..p) |col| { for (0..4) |row| { means[col] += @floatFromInt(input[2 + row * p + col]); } means[col] /= 4.0; }
    var corr = [_]f64{0} ** 25; var raw = [_]f64{1} ** 25; var bonf = [_]f64{1} ** 25; var fdr = [_]f64{1} ** 25;
    for (0..p) |i| { corr[i * p + i] = 1.0; }
    var pi = [_]usize{0} ** 10; var pj = [_]usize{0} ** 10; var pp = [_]f64{0} ** 10; var count: usize = 0;
    for (1..p) |j| { for (0..j) |i| {
        var cross: f64 = 0; var si: f64 = 0; var sj: f64 = 0;
        for (0..4) |row| { const dx = @as(f64, @floatFromInt(input[2 + row * p + i])) - means[i]; const dy = @as(f64, @floatFromInt(input[2 + row * p + j])) - means[j]; cross += dx * dy; si += dx * dx; sj += dy * dy; }
        const r = cross / @sqrt(si * sj); const pv = 1.0 - @abs(r);
        corr[i*p+j] = r; corr[j*p+i] = r; raw[i*p+j] = pv; raw[j*p+i] = pv;
        pi[count] = i; pj[count] = j; pp[count] = pv; count += 1;
    }}
    for (0..count) |k| { const adj = @min(1.0, pp[k] * @as(f64, @floatFromInt(count))); const i=pi[k];const j=pj[k];bonf[i*p+j]=adj;bonf[j*p+i]=adj; }
    var order = [_]usize{0} ** 10; for (0..count) |k| { order[k]=k; }
    for (1..count) |k| { const value=order[k];var at=k;while(at>0 and pp[order[at-1]]>pp[value]){order[at]=order[at-1];at-=1;}order[at]=value; }
    var running: f64 = 1;var pos=count;while(pos>0){pos-=1;var adj=pp[order[pos]]*@as(f64,@floatFromInt(count))/@as(f64,@floatFromInt(pos+1));adj=@min(1.0,adj);running=@min(running,adj);const k=order[pos];const i=pi[k];const j=pj[k];fdr[i*p+j]=running;fdr[j*p+i]=running;}
    var sr: i64=0;var sb:i64=0;var sf:i64=0;for(0..count)|k|{const i=pi[k];const j=pj[k];if(pp[k]<0.05)sr+=1;if(bonf[i*p+j]<0.05)sb+=1;if(fdr[i*p+j]<0.05)sf+=1;}
    var offset: usize=0;for(0..p*p)|i|putF64(output,&offset,corr[i]);for(0..p*p)|i|putF64(output,&offset,raw[i]);for(0..p*p)|i|putF64(output,&offset,bonf[i]);for(0..p*p)|i|putF64(output,&offset,fdr[i]);
    for([_]i64{4,@intCast(p),0,sr,sb,sf})|v|putI64(output,&offset,v);
    return @intCast(offset);
}
