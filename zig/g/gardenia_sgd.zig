// Clean-room bounded sequential GARDENIA MF-SGD profile.
const std=@import("std");
export fn gardenia_sgd(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    const N:usize=8;const M:usize=24;const K:usize=4;
    if(input_opt==null or length<4 or length>92)return -1;const input=input_opt.?;for(0..length)|q|if(!std.math.isFinite(input[q]))return -1;
    const uv=input[0];const iv=input[1];const mv=input[2];const kv=input[3];if(@trunc(uv)!=uv or @trunc(iv)!=iv or @trunc(mv)!=mv or @trunc(kv)!=kv or uv<1 or uv>7 or iv<1 or iv>7 or mv<1 or mv>24 or kv<1 or kv>4)return -1;
    const users:usize=@intFromFloat(uv);const items:usize=@intFromFloat(iv);const m:usize=@intFromFloat(mv);const k:usize=@intFromFloat(kv);const n=users+items;if(n>N or length!=5+users+2*m+n*k)return -1;
    const rp:usize=4;const ci=rp+users+1;const ra=ci+m;const la=ra+m;var rows:[N+1]usize=@splat(0);var cols:[M]usize=@splat(0);var ratings:[M]f64=@splat(0);var latent:[N*K]f64=@splat(0);var errors:[N]f64=@splat(0);var staged:[N*K]f64=@splat(0);
    for(0..users+1)|i|{const z=input[rp+i];if(@trunc(z)!=z or z<0 or z>@as(f64,@floatFromInt(m)))return -1;rows[i]=@intFromFloat(z);if(i>0 and rows[i]<rows[i-1])return -1;}if(rows[0]!=0 or rows[users]!=m)return -1;
    for(0..m)|e|{const z=input[ci+e];if(@trunc(z)!=z or z<0 or z>=@as(f64,@floatFromInt(items)))return -1;cols[e]=@intFromFloat(z);ratings[e]=input[ra+e];if(ratings[e] < -4 or ratings[e]>4)return -1;}
    for(0..n*k)|q|{latent[q]=input[la+q];if(latent[q]<0 or latent[q]>0.1)return -1;}const required=n*k;if(output_opt==null or capacity<required)return -2;
    for(0..3)|_|{for(0..users)|u|errors[u]=0;for(0..users)|u|{for(rows[u]..rows[u+1])|e|{const v=users+cols[e];var estimate:f64=0;for(0..k)|f|estimate+=latent[u*k+f]*latent[v*k+f];const delta=ratings[e]-estimate;errors[u]+=delta*delta;for(0..k)|f|{const ui=u*k+f;const vi=v*k+f;const pu=latent[ui];const pi=latent[vi];latent[ui]+=0.00000035*(-0.001*pu+pi*delta);latent[vi]+=0.00000035*(-0.001*pi+pu*delta);}}}var total:f64=0;for(0..users)|u|total+=errors[u];if(@sqrt(total/@as(f64,@floatFromInt(m)))<0.1)break;}
    for(0..required)|q|staged[q]=latent[q];const output=output_opt.?;for(0..required)|q|output[q]=staged[q];return @intCast(required);
}
