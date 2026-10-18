#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_points = 12;
double add(double a,double b) noexcept { volatile double v=a+b; return v; }
double sub(double a,double b) noexcept { volatile double v=a-b; return v; }
double mul(double a,double b) noexcept { volatile double v=a*b; return v; }
double divv(double a,double b) noexcept { volatile double v=a/b; return v; }
double python_distance(const double* p,std::size_t a,std::size_t b,std::size_t k) noexcept {
    double ax=p[2*a],ay=p[2*a+1],dx=sub(p[2*b],ax),dy=sub(p[2*b+1],ay),px=p[2*k],py=p[2*k+1];
    double l2=add(mul(dx,dx),mul(dy,dy));
    double t=divv(add(mul(sub(px,ax),dx),mul(sub(py,ay),dy)),l2);
    if(t<0.0)t=0.0;else if(t>1.0)t=1.0;
    return std::hypot(sub(px,add(ax,mul(t,dx))),sub(py,add(ay,mul(t,dy))));
}
double rust_distance(const double* p,std::size_t a,std::size_t b,std::size_t k,double ll) noexcept {
    double ax=p[2*a],ay=p[2*a+1],bx=p[2*b],by=p[2*b+1];
    double dx=sub(bx,ax),dy=sub(by,ay),px=p[2*k],py=p[2*k+1];
    double num=sub(add(sub(mul(dy,px),mul(dx,py)),mul(bx,ay)),mul(by,ax));
    return divv(std::fabs(num),ll);
}
bool valid_geometry(const double* p,std::size_t n,double eps) noexcept {
    if(n<3)return true;
    for(std::size_t i=0;i<n;i++)for(std::size_t j=0;j<i;j++)
        if(p[2*i]==p[2*j]&&p[2*i+1]==p[2*j+1])return false;
    for(std::size_t i=0;i+2<n;i++)for(std::size_t j=i+2;j<n;j++){
        double ax=p[2*i],ay=p[2*i+1],dx=sub(p[2*j],ax),dy=sub(p[2*j+1],ay);
        double l2=add(mul(dx,dx),mul(dy,dy)),ll=std::sqrt(l2);
        if(!std::isfinite(l2)||l2<=0.0||!std::isfinite(ll)||ll<=0.0)return false;
        double mp=0.0,mr=0.0;std::size_t ip=i,ir=i;
        for(std::size_t k=i+1;k<j;k++){
            double px=p[2*k],py=p[2*k+1];
            double t=divv(add(mul(sub(px,ax),dx),mul(sub(py,ay),dy)),l2);
            if(!(t>=0.0&&t<=1.0))return false;
            double dp=python_distance(p,i,j,k),dr=rust_distance(p,i,j,k,ll);
            if(!std::isfinite(dp)||!std::isfinite(dr))return false;
            if(dp>mp){mp=dp;ip=k;}if(dr>mr){mr=dr;ir=k;}
        }
        if(ip!=ir||((mp>eps)!=(mr>eps)))return false;
    }
    return true;
}
void simplify(const double* p,std::size_t a,std::size_t b,double eps,bool* keep) noexcept {
    if(b<=a+1)return;
    double best=0.0;std::size_t index=a;
    for(std::size_t k=a+1;k<b;k++){double d=python_distance(p,a,b,k);if(d>best){best=d;index=k;}}
    if(best>eps){keep[index]=true;simplify(p,a,index,eps,keep);simplify(p,index,b,eps,keep);}
}
}

extern "C" std::int64_t ramer_douglas_peucker(const double* input,std::size_t input_length,
                                                  double* output,std::size_t output_capacity) noexcept {
    if(input==nullptr||input_length<2||input_length>26)return -1;
    for(std::size_t i=0;i<input_length;i++)if(!std::isfinite(input[i]))return -1;
    double cv=input[0];if(cv<0.0||cv>12.0||cv!=static_cast<double>(static_cast<std::size_t>(cv)))return -1;
    std::size_t n=static_cast<std::size_t>(cv);
    if(input_length!=2+2*n||input[1]<0.0||input[1]>100.0)return -1;
    double points[2*max_points];
    for(std::size_t i=0;i<2*n;i++){if(input[2+i]<-100.0||input[2+i]>100.0)return -1;points[i]=input[2+i];}
    if(!valid_geometry(points,n,input[1]))return -1;
    bool keep[max_points]={false};if(n>0)keep[0]=true;if(n>1)keep[n-1]=true;
    if(n>2)simplify(points,0,n-1,input[1],keep);
    double staged[1+2*max_points];std::size_t outn=0;
    for(std::size_t i=0;i<n;i++)if(keep[i]){staged[1+2*outn]=points[2*i];staged[2+2*outn]=points[2*i+1];outn++;}
    staged[0]=static_cast<double>(outn);std::size_t length=1+2*outn;
    if(output==nullptr||output_capacity<length)return -2;
    for(std::size_t i=0;i<length;i++)output[i]=staged[i];
    return static_cast<std::int64_t>(length);
}
