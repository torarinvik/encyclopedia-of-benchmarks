fn putDouble(outp:[*]u8,offset:usize,value:f64) void { const bits=@as(u64,@bitCast(value));for(0..8)|b|{outp[offset+b]=@truncate(bits>>(8*b));} }
export fn ordinary_least_squares_regression(v:[*]const i64,n:usize,outp:[*]u8,cap:usize)i64 {
 if(n<5 or v[0]<2 or v[0]>32 or n!=@as(usize,@intCast(1+2*v[0])))return -1;const count:usize=@intCast(v[0]);var xs=[_]f64{0}**32;var ys=[_]f64{0}**32;var xm:f64=0;var ym:f64=0;
 for(0..count)|i|{const x=v[1+2*i];const y=v[2+2*i];if(x < -10000 or x>10000 or y < -10000 or y>10000)return -1;xs[i]=@floatFromInt(x);ys[i]=@floatFromInt(y);xm+=xs[i];ym+=ys[i];}
 xm/=@floatFromInt(count);ym/=@floatFromInt(count);var num:f64=0;var den:f64=0;for(0..count)|i|{const dx=xs[i]-xm;num+=dx*(ys[i]-ym);den+=dx*dx;}if(den==0)return -1;const slope=num/den;const intercept=ym-slope*xm;if(cap<16)return -2;putDouble(outp,0,intercept);putDouble(outp,8,slope);return 16;
}
