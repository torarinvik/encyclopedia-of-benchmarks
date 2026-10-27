const max_n: usize = 3;
const max_l: usize = 4;
const max_input: usize = 20;
const max_output: usize = 48;
const max_updates: usize = 6;
const scale: i64 = 46656;
const infinity: i64 = 9223372036854775807;

fn put64(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position+byte] = @truncate(bits >> @intCast(8*byte));
}
fn gcd64(a0: i64, b0: i64) i64 {
    var a=a0; var b=b0;
    while (b != 0) { const r=@rem(a,b); a=b; b=r; }
    return a;
}

export fn optimistic_flow_control_updates(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt==null || length<7 || length>max_input) return -1;
    const input=input_opt.?;
    const n64=input[0]; const l64=input[1]; const mode64=input[2]; const q64=input[3];
    if (n64<2 || n64>3 || l64<1 || l64>4 || mode64<0 || mode64>3 || q64<1 || q64>6) return -1;
    const n:usize=@intCast(n64); const links:usize=@intCast(l64); const mode:usize=@intCast(mode64); const updates:usize=@intCast(q64);
    if (length!=4+links+n*links) return -1;
    var cap:[max_l]i64=@splat(0); var path:[max_n*max_l]bool=@splat(false); var rate:[max_n]i64=@splat(0);
    for (0..links) |e| { cap[e]=input[4+e]; if (cap[e]<1 || cap[e]>16) return -1; }
    for (0..n) |s| {
        var used=false;
        for (0..links) |e| { const bit=input[4+links+s*links+e]; if (bit!=0&&bit!=1) return -1; path[s*max_l+e]=bit==1; used=used or bit==1; }
        if (!used) return -1;
    }
    const output_bytes=16*n;
    if (output_opt==null || capacity<output_bytes) return -2;
    const output=output_opt.?;
    for (0..updates) |step| {
        var session:usize=0;
        if (mode==0) {
            session=step%n;
        } else if (mode==1) {
            for (1..n) |s| { if (rate[s]<rate[session]) session=s; }
        } else if (mode==2) {
            var found=false;
            for (0..n) |s| {
                if (!found) {
                    var local=true;
                    for (0..n) |j| {
                        if (j!=s && local) {
                            var shares=false;
                            for (0..links) |e| { if (path[s*max_l+e] and path[j*max_l+e]) { shares=true; } }
                            if (shares && (rate[j]<rate[s] || (rate[j]==rate[s] && j<s))) { local=false; }
                        }
                    }
                    if (local) { session=s; found=true; }
                }
            }
        } else {
            var selected=links; var best_load:i64=0;
            for (0..links) |e| {
                var load:i64=0; var used=false;
                for (0..n) |s| { if (path[s*max_l+e]) { load+=rate[s]; used=true; } }
                if (used && (selected==links || load*cap[selected]>best_load*cap[e])) { selected=e; best_load=load; }
            }
            for (0..n) |s| { if (path[s*max_l+selected]) { session=s; break; } }
        }
        var best:i64=infinity; var bottleneck=links;
        for (0..links) |e| {
            if (path[session*max_l+e]) {
                var fixed:i64=0; var active:usize=1;
                for (0..n) |j| {
                    if (j!=session and path[j*max_l+e]) {
                        if (rate[j]<=rate[session]) { fixed+=rate[j]; } else { active+=1; }
                    }
                }
                var level=rate[session]; var candidate=level;
                for (0..n) |_| {
                    const numerator=cap[e]*scale-fixed;
                    const divisor:i64=@intCast(active);
                    if (numerator<0 || @rem(numerator,divisor)!=0) return -1;
                    candidate=@divTrunc(numerator,divisor);
                    if (candidate<level) return -1;
                    var next:i64=infinity;
                    for (0..n) |j| { if (j!=session && path[j*max_l+e] && rate[j]>level && rate[j]<next) next=rate[j]; }
                    if (next==infinity || candidate<=next) break;
                    var saturated:usize=0;
                    for (0..n) |j| { if (j!=session && path[j*max_l+e] && rate[j]==next) saturated+=1; }
                    fixed+=@as(i64,@intCast(saturated))*next; active-=saturated; level=next;
                }
                if (candidate<best) { best=candidate; bottleneck=e; }
            }
        }
        if (bottleneck==links) return -1;
        rate[session]=best;
        for (0..n) |j| { if (j!=session && path[j*max_l+bottleneck] && rate[j]>best) rate[j]=best; }
    }
    var staged:[max_output]u8=@splat(0);
    for (0..n) |s| { const d=gcd64(rate[s],scale); put64(&staged,16*s,@divTrunc(rate[s],d)); put64(&staged,16*s+8,@divTrunc(scale,d)); }
    for (0..output_bytes) |b| output[b]=staged[b];
    return @intCast(output_bytes);
}
