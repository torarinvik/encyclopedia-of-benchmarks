const std = @import("std");

fn putI64(out: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[word*8+b] = @truncate(bits >> @intCast(8*b));
}

export fn transit_node_routing_table_query(input_opt:?[*]const i64,length:usize,
    output_opt:?[*]u8,capacity:usize)i64{
    const input=input_opt orelse return -1;if(length<11 or length>86)return -1;
    const q0=input[0];const source=input[1];const target=input[2];if(q0<1 or q0>8 or source<0 or source>=32 or target<0 or target>=32 or input[3]!=1)return -1;
    const q:usize=@intCast(q0);var at:usize=4;const nf0=input[at];at+=1;if(nf0<1 or nf0>4 or nf0>q0 or at+2*@as(usize,@intCast(nf0))>length)return -1;const nf:usize=@intCast(nf0);
    var f=[_]usize{0}**8;var ds=[_]i64{0}**8;
    for(0..nf)|i|{const u0=input[at];const d=input[at+1];at+=2;if(u0<0 or u0>=q0 or d<0 or d>1000000)return -1;const u:usize=@intCast(u0);for(0..i)|j|{if(f[j]==u)return -1;}f[i]=u;ds[i]=d;}
    if(at>=length)return -1;const nb0=input[at];at+=1;if(nb0<1 or nb0>4 or nb0>q0 or at+2*@as(usize,@intCast(nb0))>length)return -1;const nb:usize=@intCast(nb0);
    var b=[_]usize{0}**8;var dt=[_]i64{0}**8;
    for(0..nb)|i|{const v0=input[at];const d=input[at+1];at+=2;if(v0<0 or v0>=q0 or d<0 or d>1000000)return -1;const v:usize=@intCast(v0);for(0..i)|j|{if(b[j]==v)return -1;}b[i]=v;dt[i]=d;}
    if(at+q*q!=length)return -1;var table=[_] [8]i64{[_]i64{0}**8}**8;
    for(0..q)|i|{for(0..q)|j|{const d=input[at];at+=1;if(d<0 or d>1000000)return -1;table[i][j]=d;}}
    for(0..q)|i|{if(table[i][i]!=0)return -1;}
    var best:i64=std.math.maxInt(i64);var bestu:usize=0;var bestv:usize=0;
    for(0..nf)|i|{for(0..nb)|j|{const d=ds[i]+table[f[i]][b[j]]+dt[j];if(d<best or (d==best and (f[i]<bestu or (f[i]==bestu and b[j]<bestv)))){best=d;bestu=f[i];bestv=b[j];}}}
    const output=output_opt orelse return -2;if(capacity<24)return -2;putI64(output,0,best);putI64(output,1,@intCast(bestu));putI64(output,2,@intCast(bestv));return 24;
}
