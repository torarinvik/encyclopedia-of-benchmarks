const std = @import("std");
const C = struct { re: f64, im: f64 };
fn add(a: C,b: C) C{return .{.re=a.re+b.re,.im=a.im+b.im};}
fn sub(a: C,b: C) C{return .{.re=a.re-b.re,.im=a.im-b.im};}
fn mul(a: C,b: C) C{return .{.re=a.re*b.re-a.im*b.im,.im=a.re*b.im+a.im*b.re};}
fn div(a: C,b: C) C{const d=b.re*b.re+b.im*b.im;return .{.re=(a.re*b.re+a.im*b.im)/d,.im=(a.im*b.re-a.re*b.im)/d};}
fn magnitude(a: C) f64{return @sqrt(a.re*a.re+a.im*a.im);}
fn finiteC(a: C) bool{return std.math.isFinite(a.re) and std.math.isFinite(a.im);}
fn sqrtC(a: C) C{
    const m=magnitude(a);
    const re=@sqrt(@max(0.0,(m+a.re)*0.5));
    var im=@sqrt(@max(0.0,(m-a.re)*0.5));
    if(a.im<0.0)im = -im;
    return .{.re=re,.im=im};
}
fn integerField(value: f64,low: i64,high: i64) ?i64{
    if(!std.math.isFinite(value) or value<@as(f64,@floatFromInt(low)) or value>@as(f64,@floatFromInt(high)) or @trunc(value)!=value)return null;
    return @intFromFloat(value);
}
fn evaluate(a: [7]f64,n: usize,z: C) struct{p:C,dp:C,ddp:C,scale:f64}{
    var p=C{.re=a[n],.im=0.0};var dp=C{.re=0.0,.im=0.0};var ddp=C{.re=0.0,.im=0.0};
    var k=n;
    while(k>0){k-=1;ddp=add(mul(ddp,z),.{.re=2.0*dp.re,.im=2.0*dp.im});dp=add(mul(dp,z),p);p=add(mul(p,z),.{.re=a[k],.im=0.0});}
    const radius=magnitude(z);var scale=@abs(a[n]);k=n;
    while(k>0){k-=1;scale=scale*radius+@abs(a[k]);}
    return .{.p=p,.dp=dp,.ddp=ddp,.scale=scale};
}
fn solve(a:[7]f64,n:usize,initial:C,tolerance:f64,iterations:usize)?C{
    var z=initial;var step:usize=0;
    while(step<=iterations):(step+=1){
        if(!finiteC(z))return null;
        const values=evaluate(a,n,z);
        if(!finiteC(values.p) or !finiteC(values.dp) or !finiteC(values.ddp) or !std.math.isFinite(values.scale))return null;
        if(magnitude(values.p)<=tolerance*@max(1.0,values.scale))return z;
        if(step==iterations or (values.p.re==0.0 and values.p.im==0.0))return null;
        const g=div(values.dp,values.p);const h=sub(mul(g,g),div(values.ddp,values.p));
        const rad=mul(.{.re=@floatFromInt(n-1),.im=0.0},sub(mul(.{.re=@floatFromInt(n),.im=0.0},h),mul(g,g)));
        if(!finiteC(g) or !finiteC(h) or !finiteC(rad))return null;
        const root=sqrtC(rad);const plus=add(g,root);const minus=sub(g,root);
        const denominator=if(magnitude(plus)>=magnitude(minus))plus else minus;
        const dm=magnitude(denominator);if(dm==0.0 or !std.math.isFinite(dm))return null;
        const correction=div(.{.re=@floatFromInt(n),.im=0.0},denominator);if(!finiteC(correction))return null;
        z=sub(z,correction);
    }
    return null;
}
export fn laguerre_complex_polynomial_root(input:[*c]const f64,input_length:usize,output:[*c]f64,output_capacity:usize)i64{
    if(input==null or input_length<1 or input_length>13)return -1;
    const degree_raw=integerField(input[0],2,6) orelse return -1;const n:usize=@intCast(degree_raw);
    if(input_length!=n+6)return -1;
    var a=[_]f64{0.0}**7;var i:usize=0;
    while(i<=n):(i+=1){a[i]=@floatFromInt(integerField(input[1+i],-16,16) orelse return -1);}
    if(a[n]==0.0)return -1;
    const re=integerField(input[n+2],-4000,4000) orelse return -1;const im=integerField(input[n+3],-4000,4000) orelse return -1;
    const tol=integerField(input[n+4],1,1000) orelse return -1;const iterations=integerField(input[n+5],8,128) orelse return -1;
    if(output==null or output_capacity<2)return -2;
    const initial=C{.re=@as(f64,@floatFromInt(re))/1000.0,.im=@as(f64,@floatFromInt(im))/1000.0};
    const root=solve(a,n,initial,@as(f64,@floatFromInt(tol))/1_000_000.0,@intCast(iterations)) orelse return -3;
    output[0]=root.re;output[1]=root.im;return 2;
}
