#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 12u

static double add(double a, double b) { volatile double v = a + b; return v; }
static double sub(double a, double b) { volatile double v = a - b; return v; }
static double mul(double a, double b) { volatile double v = a * b; return v; }
static double divv(double a, double b) { volatile double v = a / b; return v; }

static double python_distance(const double *p, size_t a, size_t b, size_t k)
{
    double ax=p[2*a], ay=p[2*a+1], dx=sub(p[2*b],ax), dy=sub(p[2*b+1],ay);
    double px=p[2*k], py=p[2*k+1];
    double length2=add(mul(dx,dx),mul(dy,dy));
    double t=divv(add(mul(sub(px,ax),dx),mul(sub(py,ay),dy)),length2);
    if (t < 0.0) t=0.0; else if (t > 1.0) t=1.0;
    double nx=add(ax,mul(t,dx)), ny=add(ay,mul(t,dy));
    return hypot(sub(px,nx),sub(py,ny));
}

static double rust_distance(const double *p, size_t a, size_t b, size_t k, double line_length)
{
    double ax=p[2*a], ay=p[2*a+1], bx=p[2*b], by=p[2*b+1];
    double dx=sub(bx,ax), dy=sub(by,ay), px=p[2*k], py=p[2*k+1];
    double numerator=sub(add(sub(mul(dy,px),mul(dx,py)),mul(bx,ay)),mul(by,ax));
    return divv(fabs(numerator),line_length);
}

static int valid_geometry(const double *p, size_t n, double epsilon)
{
    if (n < 3) return 1;
    for(size_t i=0;i<n;i++) for(size_t j=0;j<i;j++)
        if(p[2*i]==p[2*j] && p[2*i+1]==p[2*j+1]) return 0;
    for(size_t i=0;i+2<n;i++) for(size_t j=i+2;j<n;j++) {
        double ax=p[2*i], ay=p[2*i+1], dx=sub(p[2*j],ax), dy=sub(p[2*j+1],ay);
        double l2=add(mul(dx,dx),mul(dy,dy)), ll=sqrt(l2);
        if(!isfinite(l2)||l2<=0.0||!isfinite(ll)||ll<=0.0) return 0;
        double mp=0.0,mr=0.0; size_t ip=i,ir=i;
        for(size_t k=i+1;k<j;k++) {
            double px=p[2*k],py=p[2*k+1];
            double t=divv(add(mul(sub(px,ax),dx),mul(sub(py,ay),dy)),l2);
            if(!(t>=0.0 && t<=1.0)) return 0;
            double dp=python_distance(p,i,j,k), dr=rust_distance(p,i,j,k,ll);
            if(!isfinite(dp)||!isfinite(dr)) return 0;
            if(dp>mp){mp=dp;ip=k;} if(dr>mr){mr=dr;ir=k;}
        }
        if(ip!=ir || ((mp>epsilon)!=(mr>epsilon))) return 0;
    }
    return 1;
}

static void simplify(const double *p,size_t a,size_t b,double eps,uint8_t *keep)
{
    if(b<=a+1) return;
    double best=0.0; size_t index=a;
    for(size_t k=a+1;k<b;k++){double d=python_distance(p,a,b,k);if(d>best){best=d;index=k;}}
    if(best>eps){keep[index]=1;simplify(p,a,index,eps,keep);simplify(p,index,b,eps,keep);}
}

int64_t ramer_douglas_peucker(const double *input,size_t input_length,double *output,size_t output_capacity)
{
    if(input==NULL||input_length<2||input_length>26) return -1;
    for(size_t i=0;i<input_length;i++) if(!isfinite(input[i])) return -1;
    double countv=input[0];
    if(countv<0.0||countv>12.0||countv!=(double)(size_t)countv) return -1;
    size_t n=(size_t)countv;
    if(input_length!=2+2*n||input[1]<0.0||input[1]>100.0) return -1;
    double points[2*MAX_POINTS];
    for(size_t i=0;i<2*n;i++){if(input[2+i]<-100.0||input[2+i]>100.0)return -1;points[i]=input[2+i];}
    if(!valid_geometry(points,n,input[1])) return -1;
    uint8_t keep[MAX_POINTS]={0};
    if(n>0) keep[0]=1;
    if(n>1) keep[n-1]=1;
    if(n>2) simplify(points,0,n-1,input[1],keep);
    double staged[1+2*MAX_POINTS]; size_t outn=0;
    for(size_t i=0;i<n;i++) if(keep[i]){staged[1+2*outn]=points[2*i];staged[2+2*outn]=points[2*i+1];outn++;}
    staged[0]=(double)outn; size_t length=1+2*outn;
    if(output==NULL||output_capacity<length) return -2;
    for(size_t i=0;i<length;i++) output[i]=staged[i];
    return (int64_t)length;
}
