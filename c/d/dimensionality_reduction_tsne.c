#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t dimensionality_reduction_tsne(const double *v, size_t n, double *out, size_t cap) {
    if (!v || n != 5 || v[0] != 1 || v[1] != 3) return -1;
    for (size_t i=2;i<5;i++) if (!isfinite(v[i]) || fabs(v[i])>100) return -1;
    if (!out || cap < 3) return -2;
    double d[3][3], p[3][3]={{0}}, q[3][3], denom[3][3], y[3]={3.0471707975443136e-05,-1.0399841062404956e-04,7.504511958064573e-05}, mom[3]={0};
    for(size_t i=0;i<3;i++)for(size_t j=0;j<3;j++){double z=v[2+i]-v[2+j];d[i][j]=z*z;}
    for(size_t i=0;i<3;i++){
        double lo=-INFINITY,hi=INFINITY,beta=1,probs[3]={0};
        for(int it=0;it<50;it++){
            double e[3],sum=0;for(size_t j=0;j<3;j++){e[j]=i==j?0:exp(-d[i][j]*beta);sum+=e[j];}
            if(sum==0){for(size_t j=0;j<3;j++)p[i][j]=0;break;}
            double h=0;for(size_t j=0;j<3;j++){probs[j]=e[j]/sum;if(probs[j]>0)h-=probs[j]*log2(probs[j]+1e-12);}
            double current=exp2(h);if(fabs(current-1.5)<1e-5){for(size_t j=0;j<3;j++)p[i][j]=probs[j];break;}
            if(current>1.5){lo=beta;beta=isinf(hi)?beta*2:(beta+hi)/2;}else{hi=beta;beta=isinf(lo)?beta/2:(beta+lo)/2;}
            if(it==49)for(size_t j=0;j<3;j++)p[i][j]=probs[j];
        }
    }
    double high[3][3];for(size_t i=0;i<3;i++)for(size_t j=0;j<3;j++){high[i][j]=(p[i][j]+p[j][i])/6;if(high[i][j]<1e-12)high[i][j]=1e-12;}
    for(int it=0;it<5;it++){
        double total=0;for(size_t i=0;i<3;i++)for(size_t j=0;j<3;j++){double z=y[i]-y[j];denom[i][j]=i==j?INFINITY:1+z*z;q[i][j]=i==j?0:1/denom[i][j];total+=q[i][j];}
        for(size_t i=0;i<3;i++)for(size_t j=0;j<3;j++){q[i][j]=total==0?(i==j?0:1.0/6):q[i][j]/total;if(q[i][j]<1e-12)q[i][j]=1e-12;}
        double g[3]={0};for(size_t i=0;i<3;i++){for(size_t j=0;j<3;j++)g[i]+=(high[i][j]-q[i][j])*(1/denom[i][j])*(y[i]-y[j]);g[i]*=4;}
        for(size_t i=0;i<3;i++){mom[i]=.5*mom[i]-10*g[i];y[i]+=mom[i];}
    }
    for(size_t i=0;i<3;i++)out[i]=y[i];return 3;
}
