const std = @import("std");
const MAX_N: usize = 5;
const MAX_F: usize = 5;
const MAX_Q: usize = 8;
const MAX_P: usize = 10;
const MAX_PARSEABLE: usize = 128;

fn put(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| out[at+i] = @truncate(bits >> @intCast(8*i));
}
fn stateCost(n: usize, f: usize, d: *[MAX_P][MAX_P]i64, demand: *[MAX_N]i64,
    assignment: *[MAX_N]i64, fee: *[MAX_F]i64, mask: u32) i64 {
    var total: i64 = 0;
    for (0..f) |s| if (mask & (@as(u32,1) << @intCast(s))) != 0 { total += fee[s]; };
    for (0..n) |j| total += demand[j] * d[j][n + @as(usize, @intCast(assignment[j]))];
    return total;
}

export fn facility_location_randomized_add_delete_many(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 12 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?;
    const n0, const f0, const q0, const raw = .{ input[0], input[1], input[2], input[3] };
    if (n0 < 1 or n0 > 5 or f0 < 1 or f0 > 5 or q0 < 1 or q0 > 8 or raw <= 0
        or @as(u64,@intCast(raw)) >= (@as(u64,1) << @intCast(f0))) return -1;
    const n: usize = @intCast(n0); const f: usize = @intCast(f0); const q: usize = @intCast(q0); const p = n+f;
    if (length != 4 + 2*n + p*p + f + q) return -1;
    var mask: u32 = @intCast(raw);
    var assignment: [MAX_N]i64 = @splat(0); var demand: [MAX_N]i64 = @splat(0);
    var d: [MAX_P][MAX_P]i64 = @splat(@splat(0)); var fee: [MAX_F]i64 = @splat(0); var tape: [MAX_Q]i64 = @splat(0);
    var pos: usize = 4;
    for (0..n) |j| { assignment[j]=input[pos];pos+=1;if(assignment[j]<0 or assignment[j]>=f0 or mask & (@as(u32,1)<<@intCast(assignment[j]))==0)return -1; }
    for (0..n) |j| { demand[j]=input[pos];pos+=1;if(demand[j]<1 or demand[j]>10)return -1; }
    for (0..p) |i| { for (0..p) |j| {const v=input[pos];pos+=1;if(v<0 or v>1000)return -1;d[i][j]=v;} }
    for (0..p) |i| {if(d[i][i]!=0)return -1;for(0..p)|j|{if(i!=j and d[i][j]==0)return -1;if(d[i][j]!=d[j][i])return -1;for(0..p)|k|{if(d[i][j]>d[i][k]+d[k][j])return -1;}}}
    for (0..f) |s| {fee[s]=input[pos];pos+=1;if(fee[s]<0 or fee[s]>1000)return -1;}
    for (0..q) |t| {tape[t]=input[pos];pos+=1;if(tape[t]<0 or tape[t]>=f0)return -1;}
    var costs: [MAX_Q]i64 = @splat(0); var accepted: [MAX_Q]i64 = @splat(0);
    var current=stateCost(n,f,&d,&demand,&assignment,&fee,mask);var count:i64=0;
    for(0..q)|step|{const candidate:usize=@intCast(tape[step]);const bit:u32=@as(u32,1)<<@intCast(candidate);var did:i64=0;if(mask&bit==0){var closer:[MAX_N]bool=@splat(false);var gain:i64=-fee[candidate];for(0..n)|j|{const old:usize=@intCast(assignment[j]);if(d[j][n+candidate]<d[j][n+old]){closer[j]=true;gain+=demand[j]*(d[j][n+old]-d[j][n+candidate]);}}
        var drop:u32=0;for(0..f)|s|{if(mask&(@as(u32,1)<<@intCast(s))!=0){var cg=fee[s];for(0..n)|j|{if(@as(usize,@intCast(assignment[j]))==s and !closer[j])cg+=demand[j]*(d[j][n+s]-d[j][n+candidate]);}if(cg>0){drop|=@as(u32,1)<<@intCast(s);gain+=cg;}}}
        if(gain>0){mask=(mask|bit)&~drop;for(0..n)|j|{if(closer[j] or drop&(@as(u32,1)<<@intCast(assignment[j]))!=0)assignment[j]=@intCast(candidate);}current=stateCost(n,f,&d,&demand,&assignment,&fee,mask);did=1;count+=1;}}
        costs[step]=current;accepted[step]=did;}
    const bytes=8*(2*q+3+n);if(output_opt==null or capacity<bytes)return -2;const out=output_opt.?;pos=0;for(0..q)|t|{put(out,pos,costs[t]);pos+=8;}for(0..q)|t|{put(out,pos,accepted[t]);pos+=8;}put(out,pos,current);pos+=8;put(out,pos,@intCast(mask));pos+=8;for(0..n)|j|{put(out,pos,assignment[j]);pos+=8;}put(out,pos,count);pos+=8;return @intCast(pos);
}
