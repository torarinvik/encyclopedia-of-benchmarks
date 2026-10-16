export fn fresnel_diffract(ptr:[*c]const f64,n:usize,out:[*c]f64,cap:usize)i64{
 if(ptr==null or n!=12)return -1;const v=ptr[0..n];if(v[0]!=4 or v[1]!=1 or v[2]!=1 or v[3]!=16)return -1;for(4..12)|i|{if(!std.math.isFinite(v[i]) or @abs(v[i])>100)return -1;}if(out==null or cap<8)return -2;
 const xr=[_]f64{v[6],v[7],v[4],v[5]};const xi=[_]f64{v[10],v[11],v[8],v[9]};const cr=[_]f64{1,0,-1,0};const si=[_]f64{0,-1,0,1};var fr=[_]f64{0,0,0,0};var fi=[_]f64{0,0,0,0};
 for(0..4)|k|{for(0..4)|j|{const t=(k*j)&3;fr[k]+=xr[j]*cr[t]-xi[j]*si[t];fi[k]+=xr[j]*si[t]+xi[j]*cr[t];}}
 for(0..4)|k|{if(k%2==1){fr[k]=-fr[k];fi[k]=-fi[k];}}
 var zr=[_]f64{0,0,0,0};var zi=[_]f64{0,0,0,0};for(0..4)|j|{for(0..4)|k|{const t=(k*j)&3;const s=-si[t];zr[j]+=(fr[k]*cr[t]-fi[k]*s)*0.25;zi[j]+=(fr[k]*s+fi[k]*cr[t])*0.25;}}
 const result=[_]f64{zr[2],zr[3],zr[0],zr[1],zi[2],zi[3],zi[0],zi[1]};for(0..8)|i|out[i]=result[i];return 8;
}
const std=@import("std");
