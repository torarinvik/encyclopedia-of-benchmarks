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

#[derive(Clone, Copy)]
struct Cpx { re: f64, im: f64 }
fn add(a:Cpx,b:Cpx)->Cpx{Cpx{re:a.re+b.re,im:a.im+b.im}}
fn sub(a:Cpx,b:Cpx)->Cpx{Cpx{re:a.re-b.re,im:a.im-b.im}}
fn scale(a:Cpx,x:f64)->Cpx{Cpx{re:a.re*x,im:a.im*x}}
fn mul(a:Cpx,b:Cpx)->Cpx{Cpx{re:a.re*b.re-a.im*b.im,im:a.re*b.im+a.im*b.re}}
fn divc(a:Cpx,b:Cpx)->Cpx{let d=b.re*b.re+b.im*b.im;Cpx{re:(a.re*b.re+a.im*b.im)/d,im:(a.im*b.re-a.re*b.im)/d}}
fn fast_w(z:Cpx)->Cpx{
    const AN:[f64;10]=[2.758402e-01,2.245740e-01,1.594149e-01,9.866577e-02,5.324414e-02,2.505215e-02,1.027747e-02,3.676164e-03,1.146494e-03,3.117570e-04];
    const SIGNS:[f64;10]=[-1.0,1.0,-1.0,1.0,-1.0,1.0,-1.0,1.0,-1.0,1.0];
    const DEN_LEFT:[f64;10]=[9.869604e+00,3.947842e+01,8.882644e+01,1.579137e+02,2.467401e+02,3.553058e+02,4.836106e+02,6.316547e+02,7.994380e+02,9.869604e+02];
    if (z.re*z.re+z.im*z.im).sqrt()<6.0{
        let magnitude=(-12.0*z.im).exp();let angle=12.0*z.re;
        let e=Cpx{re:magnitude*angle.cos(),im:magnitude*angle.sin()};
        let mut w=divc(mul(Cpx{re:0.0,im:1.0},sub(Cpx{re:1.0,im:0.0},e)),scale(z,12.0));
        let mut total=Cpx{re:0.0,im:0.0};
        for n in 0..10{let top=sub(scale(e,SIGNS[n]),Cpx{re:1.0,im:0.0});let z2scaled=mul(scale(z,144.0),z);let bottom=sub(Cpx{re:DEN_LEFT[n],im:0.0},z2scaled);total=add(total,scale(divc(top,bottom),AN[n]));}
        return add(w,mul(mul(Cpx{re:0.0,im:8.124330e+01},z),total));
    }
    let a=0.512424224754768462984202823134979415014943561548661637413182;
    let b=0.275255128608410950901357962647054304017026259671664935783653;
    let c=0.051765358792987823963876628425793170829107067780337219430904;
    let d=2.724744871391589049098642037352945695982973740328335064216346;
    let z2=mul(z,z);let left=divc(Cpx{re:a,im:0.0},sub(z2,Cpx{re:b,im:0.0}));let right=divc(Cpx{re:c,im:0.0},sub(z2,Cpx{re:d,im:0.0}));
    mul(mul(Cpx{re:0.0,im:1.0},z),add(left,right))
}

#[no_mangle]
pub unsafe extern "C" fn doe_rsbench_doppler_xs(input:*const i64,length:usize)->f64{
    if input.is_null()||length<10||length>100{return INVALID;}
    let v=std::slice::from_raw_parts(input,length);
    let (nw,np,nl,energy_raw)=(v[0],v[1],v[2],v[3]);
    if nw<1||nw>4||np<0||np>8||nl<1||nl>4||energy_raw<0||energy_raw>1_000_000{return INVALID;}
    let (nw,np,nl)=(nw as usize,np as usize,nl as usize);
    let factor_base=4+nw*5;let pole_base=factor_base+nl;
    if length!=pole_base+np*9{return INVALID;}
    let energy=energy_raw as f64/SCALE_Q;
    let mut bg_t=[0.0;4];let mut bg_a=[0.0;4];let mut bg_f=[0.0;4];let mut starts=[0usize;4];let mut ends=[0usize;4];
    for i in 0..nw{let at=4+i*5;if v[at]<0||v[at]>1_000_000||v[at+1]<0||v[at+1]>1_000_000||v[at+2]<0||v[at+2]>1_000_000||v[at+3]<0||v[at+3] as usize>np||v[at+4]<v[at+3]||v[at+4] as usize>np{return INVALID;}bg_t[i]=v[at] as f64/SCALE_Q;bg_a[i]=v[at+1] as f64/SCALE_Q;bg_f[i]=v[at+2] as f64/SCALE_Q;starts[i]=v[at+3] as usize;ends[i]=v[at+4] as usize;}
    let mut pseudo=[0.0;4];let mut factors=[Cpx{re:0.0,im:0.0};4];
    for i in 0..nl{let raw=v[factor_base+i];if raw<0||raw>1_000_000{return INVALID;}pseudo[i]=raw as f64/SCALE_Q;}
    for i in 0..np{let at=pole_base+i*9;for j in 0..8{if v[at+j]<0||v[at+j]>152_500_000{return INVALID;}}if v[at+8]<0||v[at+8]>=nl as i64{return INVALID;}}
    let spacing=1.0/nw as f64;let mut window=(energy/spacing) as usize;if window==nw{window-=1;}if window>=nw{return INVALID;}
    let root_energy=energy.sqrt();
    for i in 0..nl{let mut phi=pseudo[i]*root_energy;if i==1{phi-= -phi.atan();}else if i==2{phi-=(3.0*phi/(3.0-phi*phi)).atan();}else if i==3{phi-=(phi*(15.0-phi*phi)/(15.0-6.0*phi*phi)).atan();}phi*=2.0;factors[i]=Cpx{re:phi.cos(),im:-phi.sin()};}
    let mut sig_t=energy*bg_t[window];let mut sig_a=energy*bg_a[window];let mut sig_f=energy*bg_f[window];
    for i in starts[window]..ends[window]{let at=pole_base+i*9;let ea=Cpx{re:v[at] as f64/SCALE_Q,im:v[at+1] as f64/SCALE_Q};let rt=Cpx{re:v[at+2] as f64/SCALE_Q,im:v[at+3] as f64/SCALE_Q};let ra=Cpx{re:v[at+4] as f64/SCALE_Q,im:v[at+5] as f64/SCALE_Q};let rf=Cpx{re:v[at+6] as f64/SCALE_Q,im:v[at+7] as f64/SCALE_Q};let lv=v[at+8] as usize;let z=scale(sub(Cpx{re:energy,im:0.0},ea),0.5);if z.re==0.0&&z.im==0.0{return INVALID;}let w=fast_w(z);sig_t+=mul(mul(rt,w),factors[lv]).re;sig_a+=mul(ra,w).re;sig_f+=mul(rf,w).re;}
    let sig_e=sig_t-sig_a;let result=sig_t+2.0*sig_a+3.0*sig_f+5.0*sig_e;if result.is_finite(){result}else{INVALID}
}
