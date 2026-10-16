export fn otsu_threshold(v: [*]const i64, n: usize, outp: [*]u8, cap: usize) i64 {
 if (n < 2 or v[0] < 1 or v[0] > 32 or n != @as(usize, @intCast(v[0] + 1))) return -1;
 const count: usize = @intCast(v[0]); var hist = [_]usize{0} ** 256;
 for (0..count) |j| { const p = v[j+1]; if (p < 0 or p > 255) return -1; hist[@intCast(p)] += 1; }
 var total: f64 = 0; for (0..256) |i| { total += @as(f64, @floatFromInt(i * hist[i])); }
 var maxv: f64=0; var sum: f64=0; var wb: usize=0; var threshold: usize=0;
 for (0..256) |i| { wb += hist[i]; if (wb==0) continue; const wf=count-wb; if(wf==0) break; sum += @as(f64,@floatFromInt(i*hist[i])); const mb=sum/@as(f64,@floatFromInt(wb)); const mf=(total-sum)/@as(f64,@floatFromInt(wf)); const delta=mb-mf; const variance=@as(f64,@floatFromInt(wb*wf))*delta*delta; if(variance>maxv){maxv=variance;threshold=i;} }
 if(cap<count)return -2;for(0..count)|j|{outp[j]=if(v[j+1]>@as(i64,@intCast(threshold)))255 else 0;}return @intCast(count);
}
