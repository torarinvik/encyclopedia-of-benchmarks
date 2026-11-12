const std=@import("std");
const MaxN:usize=16;const MaxM:usize=64;const MaxQ:usize=32;const MaxV:usize=17;const MaxInput:usize=276;const MaxOutput:usize=256;const MaxW:i64=1_000_000;
fn storeLe(out:[*]u8,at:usize,x:i64)void{const bits:u64=@bitCast(x);for(0..8)|b|out[at+b]=@truncate(bits>>@intCast(8*b));}
fn stoerWagner(n:usize,spokes:[MaxN]i64,m:usize,eu:[MaxM]i64,ev:[MaxM]i64,ew:[MaxM]i64)i64{
    const vc=n+1;var w:[MaxV][MaxV]i64=@splat(@splat(0));for(0..m)|e|{const u:usize=@intCast(eu[e]);const v:usize=@intCast(ev[e]);w[u][v]+=ew[e];w[v][u]+=ew[e];}for(0..n)|u|{w[u][n]+=spokes[u];w[n][u]+=spokes[u];}
    var active:[MaxV]usize=@splat(0);var count=vc;for(0..vc)|i|active[i]=i;var best:i64=std.math.maxInt(i64);
    while(count>1){var used:[MaxV]bool=@splat(false);var connection:[MaxV]i64=@splat(0);var previous:usize=MaxV;
        for(0..count)|step|{var selected:usize=MaxV;for(0..count)|z|{const u=active[z];if(!used[u]&&(selected==MaxV or connection[u]>connection[selected] or (connection[u]==connection[selected] and u<selected)))selected=u;}
            if(step+1==count){best=@min(best,connection[selected]);for(0..count)|z|{const u=active[z];if(u!=selected and u!=previous){w[previous][u]+=w[selected][u];w[u][previous]=w[previous][u];}}var pos:usize=0;while(active[pos]!=selected):(pos+=1){}for(pos+1..count)|z|active[z-1]=active[z];count-=1;break;}
            used[selected]=true;previous=selected;for(0..count)|z|{const u=active[z];if(!used[u])connection[u]+=w[selected][u];}
        }
    }return best;
}
export fn global_minimum_cut_of_dynamic_star_augmented_graph(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<3 or length>MaxInput)return -1;const input=input_opt.?;const n0=input[0];const m0=input[1];const q0=input[2];if(n0<1 or n0>16 or m0<0 or m0>64 or m0>n0*(n0-1)/2 or q0<1 or q0>32)return -1;
    const n:usize=@intCast(n0);const m:usize=@intCast(m0);const q:usize=@intCast(q0);if(length!=3+n+3*m+2*q)return -1;var pos:usize=3;var spokes:[MaxN]i64=@splat(0);for(0..n)|i|{spokes[i]=input[pos];pos+=1;if(spokes[i]<0 or spokes[i]>MaxW)return -1;}
    var eu:[MaxM]i64=@splat(0);var ev:[MaxM]i64=@splat(0);var ew:[MaxM]i64=@splat(0);var seen:[MaxN*MaxN]bool=@splat(false);
    for(0..m)|e|{const u=input[pos];const v=input[pos+1];const weight=input[pos+2];pos+=3;if(u<0 or u>=n0 or v<0 or v>=n0 or u==v or weight<0 or weight>MaxW)return -1;const a:usize=@intCast(@min(u,v));const b:usize=@intCast(@max(u,v));const slot=a*MaxN+b;if(seen[slot])return -1;seen[slot]=true;eu[e]=u;ev[e]=v;ew[e]=weight;}
    var ux:[MaxQ]usize=@splat(0);var uy:[MaxQ]i64=@splat(0);for(0..q)|i|{const x=input[pos];const y=input[pos+1];pos+=2;if(x<0 or x>=n0 or y<0 or y>MaxW)return -1;ux[i]=@intCast(x);uy[i]=y;}
    const bytes=8*q;if(bytes>MaxOutput)return -1;if(output_opt==null or capacity<bytes)return -2;var answers:[MaxQ]i64=@splat(0);for(0..q)|i|{spokes[ux[i]]=uy[i];answers[i]=stoerWagner(n,spokes,m,eu,ev,ew);}const output=output_opt.?;for(0..q)|i|storeLe(output,8*i,answers[i]);return @intCast(bytes);
}
