/*
 * Copyright (c) 2013 Argonne National Laboratory
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * Clean-room bounded adaptation of RSBench's Doppler-broadened microscopic lookup.
 */
const INVALID: f64 = -1.0e300;
const SCALE_Q: f64 = 1_000_000.0;
const Cpx = struct { re: f64, im: f64 };

fn cadd(a:Cpx,b:Cpx) Cpx{return .{.re=a.re+b.re,.im=a.im+b.im};}
fn csub(a:Cpx,b:Cpx) Cpx{return .{.re=a.re-b.re,.im=a.im-b.im};}
fn cscale(a:Cpx,x:f64) Cpx{return .{.re=a.re*x,.im=a.im*x};}
fn cmul(a:Cpx,b:Cpx) Cpx{return .{.re=a.re*b.re-a.im*b.im,.im=a.re*b.im+a.im*b.re};}
fn cdiv(a:Cpx,b:Cpx) Cpx{const d=b.re*b.re+b.im*b.im;return .{.re=(a.re*b.re+a.im*b.im)/d,.im=(a.im*b.re-a.re*b.im)/d};}
fn fastW(z:Cpx) Cpx{
    const an=[_]f64{2.758402e-01,2.245740e-01,1.594149e-01,9.866577e-02,5.324414e-02,2.505215e-02,1.027747e-02,3.676164e-03,1.146494e-03,3.117570e-04};
    const signs=[_]f64{-1,1,-1,1,-1,1,-1,1,-1,1};
    const dl=[_]f64{9.869604e+00,3.947842e+01,8.882644e+01,1.579137e+02,2.467401e+02,3.553058e+02,4.836106e+02,6.316547e+02,7.994380e+02,9.869604e+02};
    if (@sqrt(z.re*z.re+z.im*z.im)<6.0){
        const magnitude=@exp(-12.0*z.im);const angle=12.0*z.re;
        const e=Cpx{.re=magnitude*@cos(angle),.im=magnitude*@sin(angle)};
        var w=cdiv(cmul(.{.re=0.0,.im=1.0},csub(.{.re=1.0,.im=0.0},e)),cscale(z,12.0));
        var total=Cpx{.re=0.0,.im=0.0};
        for (0..10) |n| {const top=csub(cscale(e,signs[n]),.{.re=1.0,.im=0.0});const z2scaled=cmul(cscale(z,144.0),z);const bottom=csub(.{.re=dl[n],.im=0.0},z2scaled);total=cadd(total,cscale(cdiv(top,bottom),an[n]));}
        return cadd(w,cmul(cmul(.{.re=0.0,.im=8.124330e+01},z),total));
    }
    const a=0.512424224754768462984202823134979415014943561548661637413182;
    const b=0.275255128608410950901357962647054304017026259671664935783653;
    const c=0.051765358792987823963876628425793170829107067780337219430904;
    const d=2.724744871391589049098642037352945695982973740328335064216346;
    const z2=cmul(z,z);const left=cdiv(.{.re=a,.im=0.0},csub(z2,.{.re=b,.im=0.0}));const right=cdiv(.{.re=c,.im=0.0},csub(z2,.{.re=d,.im=0.0}));
    return cmul(cmul(.{.re=0.0,.im=1.0},z),cadd(left,right));
}

pub export fn doe_rsbench_doppler_xs(input:?[*]const i64,length:usize) callconv(.c) f64{
    const values=input orelse return INVALID;
    if(length<10 or length>100)return INVALID;
    if(values[0]<1 or values[0]>4 or values[1]<0 or values[1]>8 or values[2]<1 or values[2]>4 or values[3]<0 or values[3]>1_000_000)return INVALID;
    const nw:usize=@intCast(values[0]);const np:usize=@intCast(values[1]);const nl:usize=@intCast(values[2]);
    const factor_base=4+nw*5;const pole_base=factor_base+nl;
    if(length!=pole_base+np*9)return INVALID;
    const energy=@as(f64,@floatFromInt(values[3]))/SCALE_Q;
    var bg_t=[_]f64{0}**4;var bg_a=[_]f64{0}**4;var bg_f=[_]f64{0}**4;var starts=[_]usize{0}**4;var ends=[_]usize{0}**4;
    for(0..nw)|i|{const at=4+i*5;if(values[at]<0 or values[at]>1_000_000 or values[at+1]<0 or values[at+1]>1_000_000 or values[at+2]<0 or values[at+2]>1_000_000 or values[at+3]<0 or values[at+3]>@as(i64,@intCast(np)) or values[at+4]<values[at+3] or values[at+4]>@as(i64,@intCast(np)))return INVALID;bg_t[i]=@as(f64,@floatFromInt(values[at]))/SCALE_Q;bg_a[i]=@as(f64,@floatFromInt(values[at+1]))/SCALE_Q;bg_f[i]=@as(f64,@floatFromInt(values[at+2]))/SCALE_Q;starts[i]=@intCast(values[at+3]);ends[i]=@intCast(values[at+4]);}
    var pseudo=[_]f64{0}**4;var factors=[_]Cpx{.{.re=0.0,.im=0.0}}**4;
    for(0..nl)|i|{const raw=values[factor_base+i];if(raw<0 or raw>1_000_000)return INVALID;pseudo[i]=@as(f64,@floatFromInt(raw))/SCALE_Q;}
    for(0..np)|i|{const at=pole_base+i*9;for(0..8)|j|{if(values[at+j]<0 or values[at+j]>152_500_000)return INVALID;}if(values[at+8]<0 or values[at+8]>=@as(i64,@intCast(nl)))return INVALID;}
    const spacing=1.0/@as(f64,@floatFromInt(nw));var window:usize=@intFromFloat(energy/spacing);if(window==nw)window-=1;if(window>=nw)return INVALID;
    const root_energy=@sqrt(energy);
    for (0..nl) |i| {
        var phi = pseudo[i] * root_energy;
        if (i == 1) {
            phi -= -@atan(phi);
        } else if (i == 2) {
            phi -= @atan(3.0 * phi / (3.0 - phi * phi));
        } else if (i == 3) {
            phi -= @atan(phi * (15.0 - phi * phi) / (15.0 - 6.0 * phi * phi));
        }
        phi *= 2.0;
        factors[i] = .{ .re = @cos(phi), .im = -@sin(phi) };
    }
    var sig_t=energy*bg_t[window];var sig_a=energy*bg_a[window];var sig_f=energy*bg_f[window];
    for(starts[window]..ends[window])|i|{const at=pole_base+i*9;const ea=Cpx{.re=@as(f64,@floatFromInt(values[at]))/SCALE_Q,.im=@as(f64,@floatFromInt(values[at+1]))/SCALE_Q};const rt=Cpx{.re=@as(f64,@floatFromInt(values[at+2]))/SCALE_Q,.im=@as(f64,@floatFromInt(values[at+3]))/SCALE_Q};const ra=Cpx{.re=@as(f64,@floatFromInt(values[at+4]))/SCALE_Q,.im=@as(f64,@floatFromInt(values[at+5]))/SCALE_Q};const rf=Cpx{.re=@as(f64,@floatFromInt(values[at+6]))/SCALE_Q,.im=@as(f64,@floatFromInt(values[at+7]))/SCALE_Q};const lv:usize=@intCast(values[at+8]);const z=cscale(csub(.{.re=energy,.im=0.0},ea),0.5);if(z.re==0.0 and z.im==0.0)return INVALID;const w=fastW(z);sig_t+=cmul(cmul(rt,w),factors[lv]).re;sig_a+=cmul(ra,w).re;sig_f+=cmul(rf,w).re;}
    const sig_e=sig_t-sig_a;const result=sig_t+2.0*sig_a+3.0*sig_f+5.0*sig_e;
    if(!@import("std").math.isFinite(result))return INVALID;
    return result;
}
