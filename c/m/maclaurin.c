#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define BAD (-1.0e300)
static double factorial(int64_t n) { double f=1.0; for (int64_t i=2;i<=n;++i) f*= (double)i; return f; }
static double term(int64_t mode, double x, int64_t i) {
    int64_t e; double sign=1.0;
    if (mode==0) { e=i; }
    else if (mode==1) { e=2*i+1; if (i%2) sign=-1.0; }
    else { e=2*i; if (i%2) sign=-1.0; }
    return mode==0 ? pow(x,(double)e)/factorial(e) : sign/factorial(e)*pow(x,(double)e);
}
double maclaurin(const int64_t *v,size_t n) {
    if (!v || n!=3) return BAD;
    int64_t mode=v[0], xm=v[1], em=v[2];
    if (mode<0||mode>2||xm < -2000||xm>2000||em<1||em>250) return BAD;
    double x=(double)xm/1000.0, error=(double)em/1000.0, coefficient=0.0, result=0.0;
    for (int64_t i=0;i<32;++i) { result+=coefficient; coefficient=term(mode,x,i); if (fabs(coefficient)<=error) return result; }
    return BAD;
}
