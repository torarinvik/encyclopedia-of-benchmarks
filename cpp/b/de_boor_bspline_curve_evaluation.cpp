#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 24;
bool exact_integer(double x, int low, int high, int& value) noexcept {
    if (!std::isfinite(x) || x < low || x > high || std::trunc(x) != x) return false;
    value = static_cast<int>(x);
    return true;
}
bool parse(const double* input, std::size_t length, int& degree, int& count,
           double& u, const double*& knots, const double*& controls) noexcept {
    if (!input || length < 3 || length > max_input_length ||
        !exact_integer(input[0],1,3,degree) || !exact_integer(input[1],degree+1,8,count) ||
        !std::isfinite(input[2])) return false;
    const auto knot_count = static_cast<std::size_t>(count+degree+1);
    if (length != 3+knot_count+static_cast<std::size_t>(count)) return false;
    u=input[2]; knots=input+3; controls=knots+knot_count;
    for (std::size_t i=0;i<knot_count;++i) {
        if (!std::isfinite(knots[i]) || knots[i]<-1000.0 || knots[i]>1000.0 || (i && knots[i]<knots[i-1])) return false;
    }
    for (int i=0;i<count;++i)
        if (!std::isfinite(controls[i]) || controls[i]<-1000.0 || controls[i]>1000.0) return false;
    int run=1;
    for (std::size_t i=1;i<knot_count;++i) { run=knots[i]==knots[i-1]?run+1:1; if(run>degree+1)return false; }
    return knots[degree]<knots[count] && u>=knots[degree] && u<=knots[count];
}
double evaluate(int p,int n,double u,const double* U,const double* P) noexcept {
    int k=p;
    if (u==U[n]) k=n-1;
    else while(k<n-1 && u>=U[k+1]) ++k;
    double d[4]{};
    for(int j=0;j<=p;++j)d[j]=P[k-p+j];
    for(int r=1;r<=p;++r) for(int j=p;j>=r;--j) {
        const int lo=k-p+j, hi=k+j-r+1;
        const double den=U[hi]-U[lo];
        const double a=den==0.0?0.0:(u-U[lo])/den;
        d[j]=(1.0-a)*d[j-1]+a*d[j];
    }
    return d[p];
}
}

extern "C" std::int64_t de_boor_bspline_curve_evaluation(
    const double* input,std::size_t input_length,double* output,std::size_t output_capacity) noexcept {
    if (!input) return -1;
    int p,n; double u; const double *U,*P;
    if(!parse(input,input_length,p,n,u,U,P))return -1;
    if(!output || output_capacity<1)return -2;
    const double value=evaluate(p,n,u,U,P);
    if(!std::isfinite(value))return -1;
    output[0]=value; return 1;
}
