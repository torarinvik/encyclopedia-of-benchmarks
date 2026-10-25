#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result=-1.0e300;
constexpr double a1=-0.1666666666671334, a2=0.833333333809067e-2;
constexpr double a3=0.198412715551283e-3, a4=0.27557589750762e-5;
constexpr double a5=0.2507059876207e-7, a6=0.164105986683e-9;
constexpr double b1=-0.4999999999982, b2=0.4166666664651e-1;
constexpr double b3=-0.1388888805755e-2, b4=0.24801428034e-4;
constexpr double b5=-0.2754213324e-6, b6=0.20189405e-8;
constexpr double d1=0.3999999946405e-1, d2=0.96e-3, d3=0.1233153e-5;
constexpr double e2=0.48e-3, e3=0.411051e-6;

double sin_poly_legacy(double w) {
    double value=a6;
    value=value*w+a5; value=value*w+a4; value=value*w+a3;
    value=value*w+a2; value=value*w+a1; value=value*w+1.0;
    return value;
}
double sin_poly_alternating(double w) {
    double value=a6;
    value=value*w-a5; value=value*w+a4; value=value*w-a3;
    value=value*w+a2; value=value*w+a1; value=value*w+1.0;
    return value;
}
double cos_poly(double w) {
    double value=b6;
    value=value*w+b5; value=value*w+b4; value=value*w+b3;
    value=value*w+b2; value=value*w+b1; value=value*w+1.0;
    return value;
}
}

extern "C" double misc_flops(const std::int64_t *values, std::size_t length) {
    if (values==nullptr || length!=2) return invalid_result;
    const auto module_id=values[0], steps=values[1];
    if (module_id<1 || module_id>8 || steps<2 || steps>128) return invalid_result;
    double sum=0.0, result=0.0, x=0.0, u=0.0, w=0.0;
    constexpr double pi=3.14159265358979323846;
    if (module_id==1) {
        const auto n=2*steps; const double dx=1.0/static_cast<double>(n); double v=0.0;
        for (std::int64_t i=1;i<n;++i) { v+=1.0; u=v*dx; sum+=(d1+u*(d2+u*d3))/(1.0+u*(d1+u*(e2+u*e3))); }
        const double endpoint=(d1+d2+d3)/(1.0+d1+e2+e3);
        result=1.0/(dx*(endpoint+d1+2.0*sum)/2.0);
    } else if (module_id==2) {
        double sign=-5.0, partial=-1.0;
        for (std::int64_t i=0;i<steps;++i) { sign=-sign; partial+=sign; }
        double v=0.0, reciprocal_sum=0.0; u=partial; x=0.0;
        for (std::int64_t i=0;i<steps;++i) { sign=-sign; partial+=sign; u+=2.0; x=x+(sign-u); v=v-sign*u; reciprocal_sum=reciprocal_sum+sign/u; }
        const double estimate=4.0*reciprocal_sum/5.0+5.0/v; result=estimate-31.25/(v*v*v);
    } else if (module_id==3) {
        const double dx=pi/(3.0*static_cast<double>(steps)); double v=0.0;
        for (std::int64_t i=1;i<steps;++i) { v+=1.0; u=v*dx; w=u*u; sum+=u*sin_poly_alternating(w); }
        u=pi/3.0; w=u*u; result=dx*(u*sin_poly_alternating(w)+2.0*sum)/2.0;
    } else if (module_id==4) {
        const double dx=pi/(3.0*static_cast<double>(steps));
        for (std::int64_t i=1;i<steps;++i) { u=static_cast<double>(i)*dx; w=u*u; sum+=w*(w*(w*(w*(w*(b6*w+b5)+b4)+b3)+b2)+b1)+1.0; }
        u=pi/3.0; w=u*u; const double endpoint=w*(w*(w*(w*(w*(b6*w+b5)+b4)+b3)+b2)+b1)+1.0;
        result=dx*(endpoint+1.0+2.0*sum)/2.0;
    } else if (module_id==5) {
        const double dx=pi/(3.0*static_cast<double>(steps));
        for (std::int64_t i=1;i<steps;++i) { u=static_cast<double>(i)*dx; w=u*u; sum+=(u*sin_poly_legacy(w))/cos_poly(w); }
        u=pi/3.0; w=u*u; result=dx*(u*sin_poly_legacy(w)/cos_poly(w)+2.0*sum)/2.0;
    } else if (module_id==6) {
        const double dx=pi/(4.0*static_cast<double>(steps));
        for (std::int64_t i=1;i<steps;++i) { u=static_cast<double>(i)*dx; w=u*u; sum+=(u*sin_poly_legacy(w))*cos_poly(w); }
        u=pi/4.0; w=u*u; result=dx*((u*sin_poly_legacy(w))*cos_poly(w)+2.0*sum)/2.0;
    } else if (module_id==7) {
        constexpr double end=102.3321513995275; const double dx=end/static_cast<double>(steps);
        for (std::int64_t i=1;i<steps;++i) { x=static_cast<double>(i)*dx; u=x*x; sum=sum-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0); }
        x=end; u=x*x; const double endpoint=-1.0-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0); result=18.0*dx*(endpoint+2.0*sum);
    } else {
        const double dx=pi/(3.0*static_cast<double>(steps));
        for (std::int64_t i=1;i<steps;++i) { u=static_cast<double>(i)*dx; w=u*u; const double c=cos_poly(w); sum+=c*c*u*sin_poly_legacy(w); }
        u=pi/3.0; w=u*u; const double c=cos_poly(w); result=dx*((u*sin_poly_legacy(w))*c*c+2.0*sum)/2.0;
    }
    return std::isfinite(result) ? result : invalid_result;
}
