#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static const double A1=-0.1666666666671334, A2=0.833333333809067e-2;
static const double A3=0.198412715551283e-3, A4=0.27557589750762e-5;
static const double A5=0.2507059876207e-7, A6=0.164105986683e-9;
static const double B1=-0.4999999999982, B2=0.4166666664651e-1;
static const double B3=-0.1388888805755e-2, B4=0.24801428034e-4;
static const double B5=-0.2754213324e-6, B6=0.20189405e-8;
static const double D1=0.3999999946405e-1, D2=0.96e-3, D3=0.1233153e-5;
static const double E2=0.48e-3, E3=0.411051e-6;

static double sin_poly_legacy(double w) {
    double value=A6;
    value=value*w+A5; value=value*w+A4; value=value*w+A3;
    value=value*w+A2; value=value*w+A1; value=value*w+1.0;
    return value;
}

static double sin_poly_alternating(double w) {
    double value=A6;
    value=value*w-A5; value=value*w+A4; value=value*w-A3;
    value=value*w+A2; value=value*w+A1; value=value*w+1.0;
    return value;
}

static double cos_poly(double w) {
    double value=B6;
    value=value*w+B5; value=value*w+B4; value=value*w+B3;
    value=value*w+B2; value=value*w+B1; value=value*w+1.0;
    return value;
}

double misc_flops(const int64_t *values, size_t length) {
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t module_id=values[0], steps=values[1];
    if (module_id < 1 || module_id > 8 || steps < 2 || steps > 128) return INVALID_RESULT;
    double sum=0.0, result=0.0, x=0.0, u=0.0, w=0.0;

    if (module_id == 1) {
        const int64_t n=2*steps;
        const double dx=1.0/(double)n;
        double v=0.0;
        for (int64_t i=1; i<n; ++i) {
            v += 1.0;
            u=v*dx;
            sum += (D1+u*(D2+u*D3))/(1.0+u*(D1+u*(E2+u*E3)));
        }
        const double endpoint=(D1+D2+D3)/(1.0+D1+E2+E3);
        result=1.0/(dx*(endpoint+D1+2.0*sum)/2.0);
    } else if (module_id == 2) {
        double sign=-5.0, partial=-1.0;
        for (int64_t i=0; i<steps; ++i) { sign=-sign; partial += sign; }
        double v=0.0, reciprocal_sum=0.0;
        u=partial; x=0.0;
        for (int64_t i=0; i<steps; ++i) {
            sign=-sign; partial += sign; u += 2.0;
            x=x+(sign-u); v=v-sign*u; reciprocal_sum=reciprocal_sum+sign/u;
        }
        const double estimate=4.0*reciprocal_sum/5.0+5.0/v;
        result=estimate-31.25/(v*v*v);
    } else if (module_id == 3) {
        const double dx=3.14159265358979323846/(3.0*(double)steps);
        double v=0.0;
        for (int64_t i=1; i<steps; ++i) {
            v += 1.0; u=v*dx; w=u*u;
            sum += u*sin_poly_alternating(w);
        }
        u=3.14159265358979323846/3.0; w=u*u;
        result=dx*(u*sin_poly_alternating(w)+2.0*sum)/2.0;
    } else if (module_id == 4) {
        const double dx=3.14159265358979323846/(3.0*(double)steps);
        for (int64_t i=1; i<steps; ++i) {
            u=(double)i*dx; w=u*u;
            sum += w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0;
        }
        u=3.14159265358979323846/3.0; w=u*u;
        const double endpoint=w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0;
        result=dx*(endpoint+1.0+2.0*sum)/2.0;
    } else if (module_id == 5) {
        const double dx=3.14159265358979323846/(3.0*(double)steps);
        for (int64_t i=1; i<steps; ++i) {
            u=(double)i*dx; w=u*u;
            sum += (u*sin_poly_legacy(w))/cos_poly(w);
        }
        u=3.14159265358979323846/3.0; w=u*u;
        result=dx*(u*sin_poly_legacy(w)/cos_poly(w)+2.0*sum)/2.0;
    } else if (module_id == 6) {
        const double dx=3.14159265358979323846/(4.0*(double)steps);
        for (int64_t i=1; i<steps; ++i) {
            u=(double)i*dx; w=u*u;
            sum += (u*sin_poly_legacy(w))*cos_poly(w);
        }
        u=3.14159265358979323846/4.0; w=u*u;
        result=dx*((u*sin_poly_legacy(w))*cos_poly(w)+2.0*sum)/2.0;
    } else if (module_id == 7) {
        const double end=102.3321513995275, dx=end/(double)steps;
        for (int64_t i=1; i<steps; ++i) {
            x=(double)i*dx; u=x*x;
            sum=sum-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0);
        }
        x=end; u=x*x;
        const double endpoint=-1.0-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0);
        result=18.0*dx*(endpoint+2.0*sum);
    } else {
        const double dx=3.14159265358979323846/(3.0*(double)steps);
        for (int64_t i=1; i<steps; ++i) {
            u=(double)i*dx; w=u*u;
            const double cosine=cos_poly(w);
            sum += cosine*cosine*u*sin_poly_legacy(w);
        }
        u=3.14159265358979323846/3.0; w=u*u;
        const double cosine=cos_poly(w);
        result=dx*((u*sin_poly_legacy(w))*cosine*cosine+2.0*sum)/2.0;
    }
    return isfinite(result) ? result : INVALID_RESULT;
}
