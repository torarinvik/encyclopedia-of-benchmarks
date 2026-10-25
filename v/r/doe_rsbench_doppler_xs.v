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
module doe_rsbench_doppler_xs

import math

const invalid_result = -1e300
const scale_q = 1_000_000.0
struct Cpx { re f64 im f64 }

fn cadd(a Cpx,b Cpx) Cpx { return Cpx{a.re+b.re,a.im+b.im} }
fn csub(a Cpx,b Cpx) Cpx { return Cpx{a.re-b.re,a.im-b.im} }
fn cscale(a Cpx,x f64) Cpx { return Cpx{a.re*x,a.im*x} }
fn cmul(a Cpx,b Cpx) Cpx { return Cpx{a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re} }
fn cdiv(a Cpx,b Cpx) Cpx { d:=b.re*b.re+b.im*b.im;return Cpx{(a.re*b.re+a.im*b.im)/d,(a.im*b.re-a.re*b.im)/d} }
fn fast_w(z Cpx) Cpx {
    an:=[10]f64{2.758402e-01,2.245740e-01,1.594149e-01,9.866577e-02,5.324414e-02,2.505215e-02,1.027747e-02,3.676164e-03,1.146494e-03,3.117570e-04}
    signs:=[10]f64{-1,1,-1,1,-1,1,-1,1,-1,1}
    dl:=[10]f64{9.869604e+00,3.947842e+01,8.882644e+01,1.579137e+02,2.467401e+02,3.553058e+02,4.836106e+02,6.316547e+02,7.994380e+02,9.869604e+02}
    if math.sqrt(z.re*z.re+z.im*z.im)<6.0 {
        magnitude:=math.exp(-12.0*z.im);angle:=12.0*z.re
        e:=Cpx{magnitude*math.cos(angle),magnitude*math.sin(angle)}
        w:=cdiv(cmul(Cpx{0,1},csub(Cpx{1,0},e)),cscale(z,12.0))
        mut total:=Cpx{0,0}
        for n in 0..10 { top:=csub(cscale(e,signs[n]),Cpx{1,0});z2scaled:=cmul(cscale(z,144.0),z);bottom:=csub(Cpx{dl[n],0},z2scaled);total=cadd(total,cscale(cdiv(top,bottom),an[n])) }
        return cadd(w,cmul(cmul(Cpx{0,8.124330e+01},z),total))
    }
    a:=0.512424224754768462984202823134979415014943561548661637413182
    b:=0.275255128608410950901357962647054304017026259671664935783653
    c:=0.051765358792987823963876628425793170829107067780337219430904
    d:=2.724744871391589049098642037352945695982973740328335064216346
    z2:=cmul(z,z);left:=cdiv(Cpx{a,0},csub(z2,Cpx{b,0}));right:=cdiv(Cpx{c,0},csub(z2,Cpx{d,0}))
    return cmul(cmul(Cpx{0,1},z),cadd(left,right))
}

@[export: 'doe_rsbench_doppler_xs']
pub fn doe_rsbench_doppler_xs(input &i64,length usize) f64 {
    unsafe {
        if input==nil||length<10||length>100{return invalid_result}
        nw_raw,np_raw,nl_raw,e_raw:=input[0],input[1],input[2],input[3]
        if nw_raw<1||nw_raw>4||np_raw<0||np_raw>8||nl_raw<1||nl_raw>4||e_raw<0||e_raw>1_000_000{return invalid_result}
        nw,np,nl:=int(nw_raw),int(np_raw),int(nl_raw)
        factor_base:=4+nw*5;pole_base:=factor_base+nl
        if length!=usize(pole_base+np*9){return invalid_result}
        energy:=f64(e_raw)/scale_q
        mut bg_t:=[4]f64{};mut bg_a:=[4]f64{};mut bg_f:=[4]f64{};mut starts:=[4]int{};mut ends:=[4]int{}
        for i in 0..nw {at:=4+i*5;if input[at]<0||input[at]>1_000_000||input[at+1]<0||input[at+1]>1_000_000||input[at+2]<0||input[at+2]>1_000_000||input[at+3]<0||input[at+3]>np_raw||input[at+4]<input[at+3]||input[at+4]>np_raw{return invalid_result};bg_t[i]=f64(input[at])/scale_q;bg_a[i]=f64(input[at+1])/scale_q;bg_f[i]=f64(input[at+2])/scale_q;starts[i]=int(input[at+3]);ends[i]=int(input[at+4])}
        mut pseudo:=[4]f64{};mut factors:=[4]Cpx{}
        for i in 0..nl {raw:=input[factor_base+i];if raw<0||raw>1_000_000{return invalid_result};pseudo[i]=f64(raw)/scale_q}
        for i in 0..np {at:=pole_base+i*9;for j in 0..8{if input[at+j]<0||input[at+j]>152_500_000{return invalid_result}};if input[at+8]<0||input[at+8]>=i64(nl){return invalid_result}}
        spacing:=1.0/f64(nw);mut window:=int(energy/spacing);if window==nw{window--};if window<0||window>=nw{return invalid_result}
        root_energy:=math.sqrt(energy)
        for i in 0..nl {mut phi:=pseudo[i]*root_energy;if i==1{phi-= -math.atan(phi)}else if i==2{phi-=math.atan(3.0*phi/(3.0-phi*phi))}else if i==3{phi-=math.atan(phi*(15.0-phi*phi)/(15.0-6.0*phi*phi))};phi*=2.0;factors[i]=Cpx{math.cos(phi),-math.sin(phi)}}
        mut sig_t:=energy*bg_t[window];mut sig_a:=energy*bg_a[window];mut sig_f:=energy*bg_f[window]
        for i in starts[window]..ends[window] {at:=pole_base+i*9;ea:=Cpx{f64(input[at])/scale_q,f64(input[at+1])/scale_q};rt:=Cpx{f64(input[at+2])/scale_q,f64(input[at+3])/scale_q};ra:=Cpx{f64(input[at+4])/scale_q,f64(input[at+5])/scale_q};rf:=Cpx{f64(input[at+6])/scale_q,f64(input[at+7])/scale_q};lv:=int(input[at+8]);z:=cscale(csub(Cpx{energy,0},ea),0.5);if z.re==0.0&&z.im==0.0{return invalid_result};w:=fast_w(z);sig_t+=cmul(cmul(rt,w),factors[lv]).re;sig_a+=cmul(ra,w).re;sig_f+=cmul(rf,w).re}
        sig_e:=sig_t-sig_a;result:=sig_t+2.0*sig_a+3.0*sig_f+5.0*sig_e
        if !math.is_finite(result){return invalid_result};return result
    }
}
