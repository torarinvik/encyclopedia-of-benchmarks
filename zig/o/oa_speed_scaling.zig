const max_jobs: usize = 2;
const max_time: usize = 4;
const max_input: usize = 8;
const max_output: usize = 152;
const max_segments: usize = 3;

const Rat = struct { n: i64, d: i64 };
const Segment = struct { start: i64, finish: i64, speed_n: i64, speed_d: i64 };

fn gcd64(a0: i64, b0: i64) i64 {
    var a = a0;
    var b = b0;
    while (b != 0) { const r = @rem(a,b); a = b; b = r; }
    return if (a < 0) -a else a;
}
fn makeRat(n0: i64, d0: i64) Rat {
    var n = n0;
    var d = d0;
    if (d < 0) { n = -n; d = -d; }
    const g = gcd64(n,d);
    return .{ .n = @divTrunc(n,g), .d = @divTrunc(d,g) };
}
fn ratInt(x: i64) Rat { return .{ .n = x, .d = 1 }; }
fn ratAdd(a: Rat,b: Rat) Rat { return makeRat(a.n*b.d+b.n*a.d,a.d*b.d); }
fn ratSub(a: Rat,b: Rat) Rat { return makeRat(a.n*b.d-b.n*a.d,a.d*b.d); }
fn ratMul(a: Rat,b: Rat) Rat { return makeRat(a.n*b.n,a.d*b.d); }
fn ratDiv(a: Rat,b: Rat) Rat { return makeRat(a.n*b.d,a.d*b.n); }
fn ratCmp(a: Rat,b: Rat) i32 {
    const left=a.n*b.d;
    const right=b.n*a.d;
    return if (left>right) 1 else if (left<right) -1 else 0;
}
fn appendSegment(segments: *[max_segments]Segment, count: *usize,
    start: i64, finish: i64, speed: Rat) void {
    if (finish<=start or speed.n<=0) return;
    if (count.*>0 and segments[count.*-1].finish==start and
        ratCmp(speed,makeRat(segments[count.*-1].speed_n,segments[count.*-1].speed_d))==0) {
        segments[count.*-1].finish=finish;
        return;
    }
    segments[count.*]=.{.start=start,.finish=finish,.speed_n=speed.n,.speed_d=speed.d};
    count.*+=1;
}
fn put64(output: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[at+byte]=@truncate(bits >> @intCast(8*byte));
}

export fn oa_speed_scaling(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt==null or length<2 or length>max_input) return -1;
    const input=input_opt.?;
    const count64=input[0];
    if (count64<1 or count64>@as(i64,@intCast(max_jobs))) return -1;
    const n: usize=@intCast(count64);
    if (length!=1+3*n) return -1;
    var release: [max_jobs]i64=@splat(0);
    var deadline: [max_jobs]i64=@splat(0);
    var work: [max_jobs]i64=@splat(0);
    var remaining: [max_jobs]Rat=@splat(ratInt(0));
    var completion: [max_jobs]Rat=@splat(ratInt(0));
    var completed: [max_jobs]bool=@splat(false);
    for (0..n) |j| {
        const r=input[1+3*j]; const d=input[2+3*j]; const w=input[3+3*j];
        if (r<0 or r>=d or d>4 or w<1 or w>4) return -1;
        release[j]=r; deadline[j]=d; work[j]=w;
    }
    var segments: [max_segments]Segment=@splat(.{.start=0,.finish=0,.speed_n=0,.speed_d=1});
    var segment_count: usize=0;
    var energy=ratInt(0);
    for (0..max_time+1) |now_index| {
        const now: i64=@intCast(now_index);
        var has_arrival=false;
        for (0..n) |j| { if (release[j]==now) { remaining[j]=ratInt(work[j]); has_arrival=true; } }
        if (!has_arrival) continue;
        var next_release: i64=5;
        for (0..n) |j| { if (release[j]>now and release[j]<next_release) next_release=release[j]; }
        var order: [max_jobs]usize=@splat(0);
        var used: usize=0;
        for (0..n) |j| { if (remaining[j].n>0 and deadline[j]>now) { order[used]=j; used+=1; } }
        for (1..used) |i| {
            const value=order[i];
            var k=i;
            while (k>0 and (deadline[order[k-1]]>deadline[value] or
                (deadline[order[k-1]]==deadline[value] and order[k-1]>value))) { order[k]=order[k-1]; k-=1; }
            order[k]=value;
        }
        var left=now;
        while (used>0) {
            var prefix=ratInt(0); var best=ratInt(0); var best_count: usize=0;
            for (1..used+1) |k| {
                prefix=ratAdd(prefix,remaining[order[k-1]]);
                const density=ratDiv(prefix,ratInt(deadline[order[k-1]]-left));
                if (best_count==0 or ratCmp(density,best)>0) { best=density; best_count=k; }
            }
            const right=deadline[order[best_count-1]];
            const stop=if (right<next_release) right else next_release;
            appendSegment(&segments,&segment_count,left,stop,best);
            energy=ratAdd(energy,ratMul(ratMul(ratMul(best,best),best),ratInt(stop-left)));
            var cursor=ratInt(left); const stop_rat=ratInt(stop);
            for (0..best_count) |k| {
                const j=order[k];
                const finish=ratAdd(cursor,ratDiv(remaining[j],best));
                if (ratCmp(finish,stop_rat)<=0) {
                    completion[j]=finish; completed[j]=true; remaining[j]=ratInt(0); cursor=finish;
                } else {
                    remaining[j]=ratSub(remaining[j],ratMul(best,ratSub(stop_rat,cursor)));
                    cursor=stop_rat; break;
                }
            }
            if (stop<right) break;
            for (best_count..used) |k| order[k-best_count]=order[k];
            used-=best_count; left=right;
        }
    }
    for (0..n) |j| { if (!completed[j]) return -1; }
    var values: [max_output/8]i64=@splat(0);
    var fields: usize=0;
    values[fields]=@intCast(segment_count); fields+=1;
    values[fields]=energy.n; fields+=1; values[fields]=energy.d; fields+=1;
    for (0..segment_count) |s| {
        values[fields]=segments[s].start; fields+=1; values[fields]=segments[s].finish; fields+=1;
        values[fields]=segments[s].speed_n; fields+=1; values[fields]=segments[s].speed_d; fields+=1;
    }
    for (0..n) |j| { values[fields]=completion[j].n; fields+=1; values[fields]=completion[j].d; fields+=1; }
    const bytes=8*fields;
    if (output_opt==null or capacity<bytes) return -2;
    const output=output_opt.?;
    var staged: [max_output]u8=@splat(0);
    for (0..fields) |i| put64(&staged,8*i,values[i]);
    @memcpy(output[0..bytes],staged[0..bytes]);
    return @intCast(bytes);
}
