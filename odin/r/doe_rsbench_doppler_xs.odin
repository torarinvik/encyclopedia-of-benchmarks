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
package doe_rsbench_doppler_xs

import "core:c"
import "core:math"

INVALID :: -1e300
SCALE_Q :: 1_000_000.0
MAX_WINDOWS :: 4
MAX_POLES :: 8
MAX_L :: 4
Complex :: struct { re, im: f64 }

cadd :: proc(a,b:Complex)->Complex{return Complex{a.re+b.re,a.im+b.im}}
csub :: proc(a,b:Complex)->Complex{return Complex{a.re-b.re,a.im-b.im}}
cscale :: proc(a:Complex,x:f64)->Complex{return Complex{a.re*x,a.im*x}}
cmul :: proc(a,b:Complex)->Complex{return Complex{a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re}}
cdiv :: proc(a,b:Complex)->Complex{d:=b.re*b.re+b.im*b.im;return Complex{(a.re*b.re+a.im*b.im)/d,(a.im*b.re-a.re*b.im)/d}
}
fast_w :: proc(z:Complex)->Complex{
    an:=[10]f64{2.758402e-01,2.245740e-01,1.594149e-01,9.866577e-02,5.324414e-02,2.505215e-02,1.027747e-02,3.676164e-03,1.146494e-03,3.117570e-04}
    signs:=[10]f64{-1,1,-1,1,-1,1,-1,1,-1,1}
    dl:=[10]f64{9.869604e+00,3.947842e+01,8.882644e+01,1.579137e+02,2.467401e+02,3.553058e+02,4.836106e+02,6.316547e+02,7.994380e+02,9.869604e+02}
    if math.sqrt_f64(z.re*z.re+z.im*z.im)<6.0{
        magnitude:=math.exp_f64(-12.0*z.im);angle:=12.0*z.re
        e:=Complex{magnitude*math.cos(angle),magnitude*math.sin(angle)}
        w:=cdiv(cmul(Complex{0,1},csub(Complex{1,0},e)),cscale(z,12.0))
        total:=Complex{0,0}
        for n:=0;n<10;n+=1{top:=csub(cscale(e,signs[n]),Complex{1,0});z2scaled:=cmul(cscale(z,144.0),z);bottom:=csub(Complex{dl[n],0},z2scaled);total=cadd(total,cscale(cdiv(top,bottom),an[n]))}
        return cadd(w,cmul(cmul(Complex{0,8.124330e+01},z),total))
    }
    a:=0.512424224754768462984202823134979415014943561548661637413182
    b:=0.275255128608410950901357962647054304017026259671664935783653
    cc:=0.051765358792987823963876628425793170829107067780337219430904
    d:=2.724744871391589049098642037352945695982973740328335064216346
    z2:=cmul(z,z);left:=cdiv(Complex{a,0},csub(z2,Complex{b,0}));right:=cdiv(Complex{cc,0},csub(z2,Complex{d,0}))
    return cmul(cmul(Complex{0,1},z),cadd(left,right))
}

@(export)
doe_rsbench_doppler_xs :: proc "c" (input:[^]i64,length:c.size_t)->f64{
    if input==nil||length<10||length>100 do return INVALID
    nwraw,nprow,nlraw,eraw:=input[0],input[1],input[2],input[3]
    if nwraw<1||nwraw>MAX_WINDOWS||nprow<0||nprow>MAX_POLES||nlraw<1||nlraw>MAX_L||eraw<0||eraw>1_000_000 do return INVALID
    nw,np,nl:=int(nwraw),int(nprow),int(nlraw)
    factor_base:=4+nw*5;pole_base:=factor_base+nl
    if int(length)!=pole_base+np*9 do return INVALID
    energy:=f64(eraw)/SCALE_Q
    bg_t,bg_a,bg_f:=[4]f64{},[4]f64{},[4]f64{}
    starts,ends:=[4]int{},[4]int{}
    for i:=0;i<nw;i+=1{
        at:=4+i*5
        if input[at]<0||input[at]>1_000_000||input[at+1]<0||input[at+1]>1_000_000||input[at+2]<0||input[at+2]>1_000_000||input[at+3]<0||input[at+3]>nprow||input[at+4]<input[at+3]||input[at+4]>nprow do return INVALID
        bg_t[i],bg_a[i],bg_f[i]=f64(input[at])/SCALE_Q,f64(input[at+1])/SCALE_Q,f64(input[at+2])/SCALE_Q
        starts[i],ends[i]=int(input[at+3]),int(input[at+4])
    }
    pseudo:=[4]f64{};factors:=[4]Complex{}
    for i:=0;i<nl;i+=1{raw:=input[factor_base+i];if raw<0||raw>1_000_000 do return INVALID;pseudo[i]=f64(raw)/SCALE_Q}
    for i:=0;i<np;i+=1{at:=pole_base+i*9;for j:=0;j<8;j+=1{if input[at+j]<0||input[at+j]>152_500_000 do return INVALID};if input[at+8]<0||input[at+8]>=i64(nl) do return INVALID}
    spacing:=1.0/f64(nw);window:=int(energy/spacing);if window==nw do window-=1;if window<0||window>=nw do return INVALID
    root_energy:=math.sqrt_f64(energy)
    for i:=0;i<nl;i+=1{phi:=pseudo[i]*root_energy;if i==1{phi-= -math.atan(phi)}else if i==2{phi-=math.atan(3.0*phi/(3.0-phi*phi))}else if i==3{phi-=math.atan(phi*(15.0-phi*phi)/(15.0-6.0*phi*phi))};phi*=2.0;factors[i]=Complex{math.cos(phi),-math.sin(phi)}}
    sig_t,sig_a,sig_f:=energy*bg_t[window],energy*bg_a[window],energy*bg_f[window]
    for i:=starts[window];i<ends[window];i+=1{
        at:=pole_base+i*9
        ea:=Complex{f64(input[at])/SCALE_Q,f64(input[at+1])/SCALE_Q};rt:=Complex{f64(input[at+2])/SCALE_Q,f64(input[at+3])/SCALE_Q};ra:=Complex{f64(input[at+4])/SCALE_Q,f64(input[at+5])/SCALE_Q};rf:=Complex{f64(input[at+6])/SCALE_Q,f64(input[at+7])/SCALE_Q};lv:=int(input[at+8])
        z:=cscale(csub(Complex{energy,0},ea),0.5);if z.re==0.0&&z.im==0.0 do return INVALID
        w:=fast_w(z)
        sig_t+=cmul(cmul(rt,w),factors[lv]).re;sig_a+=cmul(ra,w).re;sig_f+=cmul(rf,w).re
    }
    sig_e:=sig_t-sig_a;result:=sig_t+2.0*sig_a+3.0*sig_f+5.0*sig_e
    if !math.is_finite(result) do return INVALID
    return result
}
