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
module doe_rsbench_doppler_xs;
import "core:math";

const double INVALID_F64 = -1.0e300;
const double SCALE_Q = 1000000.0;
const int MAX_WINDOWS = 4, MAX_POLES = 8, MAX_L = 4;

struct Cpx { double re; double im; }
fn Cpx cadd(Cpx a,Cpx b){return Cpx{a.re+b.re,a.im+b.im};}
fn Cpx csub(Cpx a,Cpx b){return Cpx{a.re-b.re,a.im-b.im};}
fn Cpx cscale(Cpx a,double x){return Cpx{a.re*x,a.im*x};}
fn Cpx cmul(Cpx a,Cpx b){return Cpx{a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re};}
fn Cpx cdiv(Cpx a,Cpx b){double d=b.re*b.re+b.im*b.im;return Cpx{(a.re*b.re+a.im*b.im)/d,(a.im*b.re-a.re*b.im)/d};}

fn Cpx fast_w(Cpx z){
    double[10] an={2.758402e-01,2.245740e-01,1.594149e-01,9.866577e-02,5.324414e-02,2.505215e-02,1.027747e-02,3.676164e-03,1.146494e-03,3.117570e-04};
    double[10] signs={-1,1,-1,1,-1,1,-1,1,-1,1};
    double[10] dl={9.869604e+00,3.947842e+01,8.882644e+01,1.579137e+02,2.467401e+02,3.553058e+02,4.836106e+02,6.316547e+02,7.994380e+02,9.869604e+02};
    if(math.sqrt(z.re*z.re+z.im*z.im)<6.0){
        double magnitude=math.exp(-12.0*z.im),angle=12.0*z.re;
        Cpx e=Cpx{magnitude*math.cos(angle),magnitude*math.sin(angle)};
        Cpx w=cdiv(cmul(Cpx{0.0,1.0},csub(Cpx{1.0,0.0},e)),cscale(z,12.0));
        Cpx total=Cpx{0.0,0.0};
        for(int n=0;n<10;n++){Cpx top=csub(cscale(e,signs[n]),Cpx{1.0,0.0});Cpx z2scaled=cmul(cscale(z,144.0),z);Cpx bottom=csub(Cpx{dl[n],0.0},z2scaled);total=cadd(total,cscale(cdiv(top,bottom),an[n]));}
        return cadd(w,cmul(cmul(Cpx{0.0,8.124330e+01},z),total));
    }
    double a=0.512424224754768462984202823134979415014943561548661637413182;
    double b=0.275255128608410950901357962647054304017026259671664935783653;
    double c=0.051765358792987823963876628425793170829107067780337219430904;
    double d=2.724744871391589049098642037352945695982973740328335064216346;
    Cpx z2=cmul(z,z),left=cdiv(Cpx{a,0.0},csub(z2,Cpx{b,0.0})),right=cdiv(Cpx{c,0.0},csub(z2,Cpx{d,0.0}));
    return cmul(cmul(Cpx{0.0,1.0},z),cadd(left,right));
}

fn double doe_rsbench_doppler_xs(long* input,usz length) @export("doe_rsbench_doppler_xs") {
    if(input==null||length<10||length>100)return INVALID_F64;
    long nw_raw=input[0],np_raw=input[1],nl_raw=input[2],energy_raw=input[3];
    if(nw_raw<1||nw_raw>MAX_WINDOWS||np_raw<0||np_raw>MAX_POLES||nl_raw<1||nl_raw>MAX_L||energy_raw<0||energy_raw>1000000)return INVALID_F64;
    int nw=(int)nw_raw,np=(int)np_raw,nl=(int)nl_raw;
    usz factor_base=4+(usz)nw*5,pole_base=factor_base+(usz)nl;
    if(length!=pole_base+(usz)np*9)return INVALID_F64;
    double energy=(double)energy_raw/SCALE_Q;
    double[MAX_WINDOWS] bt=zeroed,ba=zeroed,bf=zeroed;
    int[MAX_WINDOWS] starts=zeroed,ends=zeroed;
    for(int i=0;i<nw;i++){
        usz at=4+(usz)i*5;
        if(input[at]<0||input[at]>1000000||input[at+1]<0||input[at+1]>1000000||input[at+2]<0||input[at+2]>1000000||input[at+3]<0||input[at+3]>np||input[at+4]<input[at+3]||input[at+4]>np)return INVALID_F64;
        bt[i]=(double)input[at]/SCALE_Q;ba[i]=(double)input[at+1]/SCALE_Q;bf[i]=(double)input[at+2]/SCALE_Q;starts[i]=(int)input[at+3];ends[i]=(int)input[at+4];
    }
    double[MAX_L] pseudo=zeroed,factors_re=zeroed,factors_im=zeroed;
    for(int i=0;i<nl;i++){long v=input[factor_base+(usz)i];if(v<0||v>1000000)return INVALID_F64;pseudo[i]=(double)v/SCALE_Q;}
    for(int i=0;i<np;i++){usz at=pole_base+(usz)i*9;for(int j=0;j<8;j++)if(input[at+(usz)j]<0||input[at+(usz)j]>152500000)return INVALID_F64;if(input[at+8]<0||input[at+8]>=nl)return INVALID_F64;}
    double spacing=1.0/(double)nw;int window=(int)(energy/spacing);if(window==nw)window--;if(window<0||window>=nw)return INVALID_F64;
    double root_energy=math.sqrt(energy);
    for(int i=0;i<nl;i++){double phi=pseudo[i]*root_energy;if(i==1)phi-= -math.atan(phi);else if(i==2)phi-=math.atan(3.0*phi/(3.0-phi*phi));else if(i==3)phi-=math.atan(phi*(15.0-phi*phi)/(15.0-6.0*phi*phi));phi*=2.0;factors_re[i]=math.cos(phi);factors_im[i]= -math.sin(phi);}
    double sig_t=energy*bt[window],sig_a=energy*ba[window],sig_f=energy*bf[window];
    for(int i=starts[window];i<ends[window];i++){
        usz at=pole_base+(usz)i*9;Cpx ea=Cpx{(double)input[at]/SCALE_Q,(double)input[at+1]/SCALE_Q};
        Cpx rt=Cpx{(double)input[at+2]/SCALE_Q,(double)input[at+3]/SCALE_Q};Cpx ra=Cpx{(double)input[at+4]/SCALE_Q,(double)input[at+5]/SCALE_Q};Cpx rf=Cpx{(double)input[at+6]/SCALE_Q,(double)input[at+7]/SCALE_Q};int lv=(int)input[at+8];
        Cpx z=cscale(csub(Cpx{energy,0.0},ea),0.5);if(z.re==0.0&&z.im==0.0)return INVALID_F64;
        Cpx w=fast_w(z);Cpx tf=Cpx{factors_re[lv],factors_im[lv]};
        sig_t+=cmul(cmul(rt,w),tf).re;sig_a+=cmul(ra,w).re;sig_f+=cmul(rf,w).re;
    }
    double sig_e=sig_t-sig_a;double result=sig_t+2.0*sig_a+3.0*sig_f+5.0*sig_e;
    return math.is_finite(result)?result:INVALID_F64;
}
