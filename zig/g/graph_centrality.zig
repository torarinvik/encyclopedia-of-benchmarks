const std = @import("std");

fn put(o: []u8, a: usize, v: i64) void { const b=@as(u64,@bitCast(v)); for(0..8)|i|o[a*8+i]=@truncate(b>>@as(u6,@intCast(8*i))); }
export fn graph_centrality(input:[*c]const i64,len:usize,output:[*c]u8,cap:usize)i64{
 if(input==null or len<2)return -1;const x=input[0..len];const nn=x[0];const ee=x[1];if(nn<1 or nn>16 or ee<0 or ee>nn*(nn-1) or len!=2+3*@as(usize,@intCast(ee)))return -1;const n:usize=@intCast(nn);const e:usize=@intCast(ee);const inf=std.math.maxInt(i64);var d: [16][16]i64 = @splat(@splat(inf));for(0..n)|i|d[i][i]=0;
 for(0..e)|z|{const a=x[2+3*z];const b=x[3+3*z];const w=x[4+3*z];if(a<0 or a>=nn or b<0 or b>=nn or a==b or w<1 or w>1000000 or d[@intCast(a)][@intCast(b)]!=inf)return -1;d[@intCast(a)][@intCast(b)]=w;}
 for(0..n)|k|for(0..n)|i|{if(d[i][k]==inf)continue;for(0..n)|j|{if(d[k][j]!=inf and d[i][k]+d[k][j]<d[i][j])d[i][j]=d[i][k]+d[k][j];}};
 var c:i64=-1;var m:i64=-1;var be:i64=inf;var bh:f64=-1.0;if(n==1){c=0;m=0;}else{for(0..n)|i|{var r=false;var ec:i64=0;var h:f64=0;for(0..n)|j|{if(i!=j and d[i][j]!=inf){r=true;ec=@max(ec,d[i][j]);h+=1.0/@as(f64,@floatFromInt(d[i][j]));}}if(r and ec<be){be=ec;c=@intCast(i);}if(r and h>bh){bh=h;m=@intCast(i);}}}
 if(output==null or cap<16)return -2;const o=output[0..16];put(o,0,c);put(o,1,m);return 16;
}
