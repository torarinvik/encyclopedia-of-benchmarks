#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
struct Complex { double re, im; };
constexpr int max_degree = 6;
Complex add(Complex a, Complex b) noexcept { return {a.re+b.re, a.im+b.im}; }
Complex sub(Complex a, Complex b) noexcept { return {a.re-b.re, a.im-b.im}; }
Complex mul(Complex a, Complex b) noexcept { return {a.re*b.re-a.im*b.im, a.re*b.im+a.im*b.re}; }
Complex div(Complex a, Complex b) noexcept {
    const double den=b.re*b.re+b.im*b.im;
    return {(a.re*b.re+a.im*b.im)/den, (a.im*b.re-a.re*b.im)/den};
}
double magnitude(Complex a) noexcept { return std::hypot(a.re,a.im); }
bool finite(Complex a) noexcept { return std::isfinite(a.re)&&std::isfinite(a.im); }
Complex square_root(Complex a) noexcept {
    const double m=magnitude(a);
    const double re=std::sqrt(std::max(0.0,(m+a.re)*0.5));
    double im=std::sqrt(std::max(0.0,(m-a.re)*0.5));
    if (a.im<0.0) im=-im;
    return {re,im};
}
bool integer_field(double value,int low,int high,int& out) noexcept {
    if(!std::isfinite(value)||value<low||value>high||std::trunc(value)!=value)return false;
    out=static_cast<int>(value);return true;
}
void evaluate(const double* a,int n,Complex z,Complex& p,Complex& dp,Complex& ddp,double& scale) noexcept {
    p={a[n],0.0};dp={0.0,0.0};ddp={0.0,0.0};
    for(int k=n-1;k>=0;--k){
        ddp=add(mul(ddp,z),{2.0*dp.re,2.0*dp.im});
        dp=add(mul(dp,z),p);
        p=add(mul(p,z),{a[k],0.0});
    }
    const double radius=magnitude(z);scale=std::abs(a[n]);
    for(int k=n-1;k>=0;--k)scale=scale*radius+std::abs(a[k]);
}
int solve(const double* a,int n,Complex z,double tolerance,int iterations,Complex& result) noexcept {
    for(int step=0;step<=iterations;++step){
        if(!finite(z))return -3;
        Complex p,dp,ddp;double scale;evaluate(a,n,z,p,dp,ddp,scale);
        if(!finite(p)||!finite(dp)||!finite(ddp)||!std::isfinite(scale))return -3;
        if(magnitude(p)<=tolerance*std::max(1.0,scale)){result=z;return 2;}
        if(step==iterations||(p.re==0.0&&p.im==0.0))return -3;
        const Complex g=div(dp,p);
        const Complex h=sub(mul(g,g),div(ddp,p));
        const Complex radicand=mul({static_cast<double>(n-1),0.0},
            sub(mul({static_cast<double>(n),0.0},h),mul(g,g)));
        if(!finite(g)||!finite(h)||!finite(radicand))return -3;
        const Complex root=square_root(radicand),plus=add(g,root),minus=sub(g,root);
        const Complex denominator=magnitude(plus)>=magnitude(minus)?plus:minus;
        const double denominator_abs=magnitude(denominator);
        if(denominator_abs==0.0||!std::isfinite(denominator_abs))return -3;
        const Complex correction=div({static_cast<double>(n),0.0},denominator);
        if(!finite(correction))return -3;
        z=sub(z,correction);
    }
    return -3;
}
}

extern "C" std::int64_t laguerre_complex_polynomial_root(
    const double* input,std::size_t input_length,double* output,std::size_t output_capacity) noexcept {
    if(input==nullptr||input_length<1||input_length>13)return -1;
    int degree;
    if(!integer_field(input[0],2,max_degree,degree)||input_length!=static_cast<std::size_t>(degree+6))return -1;
    double a[max_degree+1];int decoded;
    for(int i=0;i<=degree;++i){if(!integer_field(input[1+i],-16,16,decoded))return -1;a[i]=decoded;}
    if(a[degree]==0.0)return -1;
    int re_milli,im_milli,tolerance_micro,iterations;
    if(!integer_field(input[degree+2],-4000,4000,re_milli)||
       !integer_field(input[degree+3],-4000,4000,im_milli)||
       !integer_field(input[degree+4],1,1000,tolerance_micro)||
       !integer_field(input[degree+5],8,128,iterations))return -1;
    if(output==nullptr||output_capacity<2)return -2;
    Complex result;
    const int status=solve(a,degree,{re_milli/1000.0,im_milli/1000.0},tolerance_micro/1e6,iterations,result);
    if(status!=2||!finite(result))return -3;
    output[0]=result.re;output[1]=result.im;return 2;
}
