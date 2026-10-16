#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
#define MAX_SAMPLES 16

double gradient_boosting_regressor(const int64_t *v, size_t len) {
    if (v == NULL || len < 8 || len > 36) return INVALID_RESULT;
    int64_t n64=v[0], rounds=v[1], rate_i=v[2], query_i=v[3];
    if (n64<2 || n64>MAX_SAMPLES || rounds<1 || rounds>12 || rate_i<1 || rate_i>1000000 || len!=4+(size_t)(2*n64)) return INVALID_RESULT;
    size_t n=(size_t)n64;
    double x[MAX_SAMPLES], y[MAX_SAMPLES], pred[MAX_SAMPLES], residual[MAX_SAMPLES];
    for(size_t i=0;i<n;i++) {
        int64_t xi=v[4+i], yi=v[4+n+i];
        if(xi < -1000 || xi > 1000 || yi < -1000000 || yi > 1000000 || (i && v[3+i]>=xi)) return INVALID_RESULT;
        x[i]=(double)xi; y[i]=(double)yi/1000.0;
    }
    if(query_i < -1000 || query_i > 1000) return INVALID_RESULT;
    double mean=0.0; for(size_t i=0;i<n;i++) mean+=y[i]; mean/=(double)n;
    for(size_t i=0;i<n;i++) pred[i]=mean;
    double qpred=mean, rate=(double)rate_i/1000000.0;
    for(int64_t r=0;r<rounds;r++) {
        double sum=0.0; for(size_t i=0;i<n;i++){residual[i]=y[i]-pred[i];sum+=residual[i];}
        int constant=1; for(size_t i=1;i<n;i++) if(residual[i]!=residual[0]) constant=0;
        double best=1.0e300, left=0.0,right=0.0; size_t best_split=n;
        if(!constant) for(size_t s=0;s+1<n;s++) {
            size_t nl=s+1,nr=n-nl; double sl=0.0,sr=0.0;
            for(size_t i=0;i<nl;i++) sl+=residual[i]; for(size_t i=nl;i<n;i++) sr+=residual[i];
            double lm=sl/(double)nl,rm=sr/(double)nr,err=0.0;
            for(size_t i=0;i<nl;i++){double d=residual[i]-lm;err+=d*d;}
            for(size_t i=nl;i<n;i++){double d=residual[i]-rm;err+=d*d;}
            if(err<best){best=err;best_split=s;left=lm;right=rm;}
        }
        if(best_split==n){double leaf=sum/(double)n;for(size_t i=0;i<n;i++)pred[i]+=rate*leaf;qpred+=rate*leaf;}
        else {double threshold=(x[best_split]+x[best_split+1])/2.0;for(size_t i=0;i<n;i++)pred[i]+=rate*(x[i]<=threshold?left:right);qpred+=rate*((double)query_i<=threshold?left:right);}
    }
    return qpred;
}
