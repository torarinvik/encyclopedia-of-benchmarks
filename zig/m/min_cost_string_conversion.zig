const MAX_CELLS: usize = 1089;
fn putI64(out: [*]u8, pos: *usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |b| { out[pos.*] = @truncate(bits >> @intCast(8*b)); pos.* += 1; } }
pub export fn min_cost_string_conversion(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 6 or length > 70) return -1;
    const v = input.?; const sn=v[0]; if(sn<0 or sn>32)return -1; const src:usize=@intCast(sn); const dp=1+src; if(dp>=length)return -1;
    const dn=v[dp];if(dn<0 or dn>32)return -1;const dst:usize=@intCast(dn);if(length!=6+src+dst)return -1;const tp=dp+1;const cp=tp+dst;
    for(0..src)|i|{if(v[1+i]<0 or v[1+i]>127)return -1;}for(0..dst)|j|{if(v[tp+j]<0 or v[tp+j]>127)return -1;}for(0..4)|k|{if(v[cp+k]< -1000 or v[cp+k]>1000)return -1;}
    const cc=v[cp];const rc=v[cp+1];const dc=v[cp+2];const ic=v[cp+3];const rows=src+1;const cols=dst+1;const cells=rows*cols;
    var costs=[_]i64{0}**MAX_CELLS;var codes=[_]i64{0}**MAX_CELLS;var ca=[_]i64{0}**MAX_CELLS;var cb=[_]i64{0}**MAX_CELLS;
    for(1..cols)|j|{const x=j;costs[x]=costs[x-1]+ic;codes[x]=4;cb[x]=v[tp+j-1];}for(1..rows)|i|{const x=i*cols;costs[x]=costs[x-cols]+dc;codes[x]=3;ca[x]=v[i];}
    for(1..rows)|i|{for(1..cols)|j|{const x=i*cols+j;const a=v[i];const b=v[tp+j-1];const same=a==b;var best=costs[x-cols-1]+(if(same)cc else rc);var op:i64=if(same)1 else 2;var aa=a;var bb:i64=if(same)0 else b;const deletion=costs[x-cols]+dc;if(deletion<best){best=deletion;op=3;aa=a;bb=0;}const insertion=costs[x-1]+ic;if(insertion<best){best=insertion;op=4;aa=0;bb=b;}costs[x]=best;codes[x]=op;ca[x]=aa;cb[x]=bb;}}
    const needed=32+cells*32;if(output==null or capacity<needed)return -2;const out=output.?;var p:usize=0;putI64(out,&p,@intCast(rows));putI64(out,&p,@intCast(cols));for(0..cells)|x|putI64(out,&p,costs[x]);putI64(out,&p,@intCast(rows));putI64(out,&p,@intCast(cols));for(0..cells)|x|{putI64(out,&p,codes[x]);putI64(out,&p,ca[x]);putI64(out,&p,cb[x]);}return @intCast(p);
}
