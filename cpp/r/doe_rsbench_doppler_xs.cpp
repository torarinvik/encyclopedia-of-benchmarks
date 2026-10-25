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
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid = -1.0e300, scale_q = 1000000.0;
constexpr int max_windows = 4, max_poles = 8, max_l = 4;
struct Cpx { double re, im; };
Cpx add(Cpx a, Cpx b) { return {a.re + b.re, a.im + b.im}; }
Cpx sub(Cpx a, Cpx b) { return {a.re - b.re, a.im - b.im}; }
Cpx scale(Cpx a, double x) { return {a.re * x, a.im * x}; }
Cpx mul(Cpx a, Cpx b) { return {a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re}; }
Cpx divc(Cpx a, Cpx b) {
    const double denominator = b.re * b.re + b.im * b.im;
    return {(a.re * b.re + a.im * b.im) / denominator,
            (a.im * b.re - a.re * b.im) / denominator};
}
Cpx fast_w(Cpx z) {
    constexpr std::array<double, 10> an = {2.758402e-01,2.245740e-01,1.594149e-01,9.866577e-02,5.324414e-02,
        2.505215e-02,1.027747e-02,3.676164e-03,1.146494e-03,3.117570e-04};
    constexpr std::array<double, 10> signs = {-1,1,-1,1,-1,1,-1,1,-1,1};
    constexpr std::array<double, 10> den_left = {9.869604e+00,3.947842e+01,8.882644e+01,1.579137e+02,
        2.467401e+02,3.553058e+02,4.836106e+02,6.316547e+02,7.994380e+02,9.869604e+02};
    if (std::sqrt(z.re*z.re + z.im*z.im) < 6.0) {
        const double magnitude = std::exp(-12.0 * z.im), angle = 12.0 * z.re;
        const Cpx e = {magnitude * std::cos(angle), magnitude * std::sin(angle)};
        Cpx w = divc(mul({0.0,1.0}, sub({1.0,0.0}, e)), scale(z,12.0));
        Cpx total = {0.0,0.0};
        for (int n=0;n<10;n++) {
            const Cpx top = sub(scale(e,signs[n]),{1.0,0.0});
            const Cpx z2scaled = mul(scale(z,144.0),z);
            const Cpx bottom = sub({den_left[n],0.0},z2scaled);
            total = add(total,scale(divc(top,bottom),an[n]));
        }
        w = add(w,mul(mul({0.0,8.124330e+01},z),total));
        return w;
    }
    constexpr double a=0.512424224754768462984202823134979415014943561548661637413182;
    constexpr double b=0.275255128608410950901357962647054304017026259671664935783653;
    constexpr double c=0.051765358792987823963876628425793170829107067780337219430904;
    constexpr double d=2.724744871391589049098642037352945695982973740328335064216346;
    const Cpx z2=mul(z,z);
    const Cpx left=divc({a,0.0},sub(z2,{b,0.0}));
    const Cpx right=divc({c,0.0},sub(z2,{d,0.0}));
    return mul(mul({0.0,1.0},z),add(left,right));
}
}

extern "C" double doe_rsbench_doppler_xs(const std::int64_t *input, std::size_t length) {
    if (input==nullptr || length<10 || length>100) return invalid;
    const std::int64_t nwin=input[0], npole=input[1], nl=input[2], energy_raw=input[3];
    if (nwin<1 || nwin>max_windows || npole<0 || npole>max_poles || nl<1 || nl>max_l || energy_raw<0 || energy_raw>1000000) return invalid;
    const std::size_t factor_base=4+static_cast<std::size_t>(nwin)*5;
    const std::size_t pole_base=factor_base+static_cast<std::size_t>(nl);
    if (length!=pole_base+static_cast<std::size_t>(npole)*9) return invalid;
    const double energy=static_cast<double>(energy_raw)/scale_q;
    std::array<double,max_windows> bg_t{},bg_a{},bg_f{};
    std::array<int,max_windows> starts{},ends{};
    for (int i=0;i<nwin;i++) {
        const std::size_t at=4+static_cast<std::size_t>(i)*5;
        if (input[at]<0 || input[at]>1000000 || input[at+1]<0 || input[at+1]>1000000 || input[at+2]<0 || input[at+2]>1000000 ||
            input[at+3]<0 || input[at+3]>npole || input[at+4]<input[at+3] || input[at+4]>npole) return invalid;
        bg_t[i]=static_cast<double>(input[at])/scale_q; bg_a[i]=static_cast<double>(input[at+1])/scale_q; bg_f[i]=static_cast<double>(input[at+2])/scale_q;
        starts[i]=static_cast<int>(input[at+3]); ends[i]=static_cast<int>(input[at+4]);
    }
    std::array<double,max_l> pseudo{}; std::array<Cpx,max_l> factors{};
    for (int i=0;i<nl;i++) { const auto v=input[factor_base+static_cast<std::size_t>(i)]; if(v<0||v>1000000)return invalid; pseudo[i]=static_cast<double>(v)/scale_q; }
    for (int i=0;i<npole;i++) { const std::size_t at=pole_base+static_cast<std::size_t>(i)*9; for(int j=0;j<8;j++)if(input[at+j]<0||input[at+j]>152500000)return invalid; if(input[at+8]<0||input[at+8]>=nl)return invalid; }
    const double spacing=1.0/static_cast<double>(nwin);
    int window=static_cast<int>(energy/spacing);
    if(window==nwin)window--;
    if(window<0||window>=nwin)return invalid;
    const double root_energy=std::sqrt(energy);
    for(int i=0;i<nl;i++){
        double phi=pseudo[i]*root_energy;
        if(i==1)phi-= -std::atan(phi);
        else if(i==2)phi-=std::atan(3.0*phi/(3.0-phi*phi));
        else if(i==3)phi-=std::atan(phi*(15.0-phi*phi)/(15.0-6.0*phi*phi));
        phi*=2.0; factors[i]={std::cos(phi),-std::sin(phi)};
    }
    double sig_t=energy*bg_t[window],sig_a=energy*bg_a[window],sig_f=energy*bg_f[window];
    for(int i=starts[window];i<ends[window];i++){
        const std::size_t at=pole_base+static_cast<std::size_t>(i)*9;
        const Cpx ea={static_cast<double>(input[at])/scale_q,static_cast<double>(input[at+1])/scale_q};
        const Cpx rt={static_cast<double>(input[at+2])/scale_q,static_cast<double>(input[at+3])/scale_q};
        const Cpx ra={static_cast<double>(input[at+4])/scale_q,static_cast<double>(input[at+5])/scale_q};
        const Cpx rf={static_cast<double>(input[at+6])/scale_q,static_cast<double>(input[at+7])/scale_q};
        const int l=static_cast<int>(input[at+8]);
        const Cpx z=scale(sub({energy,0.0},ea),0.5);
        if(z.re==0.0&&z.im==0.0)return invalid;
        const Cpx w=fast_w(z);
        sig_t+=mul(mul(rt,w),factors[l]).re; sig_a+=mul(ra,w).re; sig_f+=mul(rf,w).re;
    }
    const double sig_e=sig_t-sig_a;
    const double result=sig_t+2.0*sig_a+3.0*sig_f+5.0*sig_e;
    return std::isfinite(result)?result:invalid;
}
