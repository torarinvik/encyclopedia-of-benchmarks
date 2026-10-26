/* Clean-room bounded GraphSAGE mean-neighbor aggregation. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_N 8
#define MAX_M 24
#define MAX_D 4
#define MAX_INPUT (4+MAX_N+MAX_M+MAX_N*MAX_D)
int64_t graphai_sage_aggregation(const double *input,size_t length,double *output,size_t capacity){
    if(!input||length<4||length>MAX_INPUT)return -1;
    for(size_t q=0;q<length;++q)if(!isfinite(input[q]))return -1;
    double nv=input[0],mv=input[1],dv=input[2];
    if(trunc(nv)!=nv||trunc(mv)!=mv||trunc(dv)!=dv||nv<1||nv>MAX_N||mv<0||mv>MAX_M||dv<1||dv>MAX_D)return -1;
    size_t n=(size_t)nv,m=(size_t)mv,d=(size_t)dv;if(length!=4+n+m+n*d)return -1;
    size_t rp=3,ci=rp+n+1,xf=ci+m;if(input[rp]!=0||input[ci-1]!=(double)m)return -1;
    size_t rows[MAX_N+1],cols[MAX_M];
    for(size_t i=0;i<=n;++i){double x=input[rp+i];if(trunc(x)!=x||x<0||x>m)return -1;rows[i]=(size_t)x;if(i&&rows[i]<rows[i-1])return -1;}
    for(size_t e=0;e<m;++e){double x=input[ci+e];if(trunc(x)!=x||x<0||x>=n)return -1;cols[e]=(size_t)x;}
    for(size_t q=0;q<n*d;++q)if(input[xf+q]<-8||input[xf+q]>8)return -1;
    size_t required=n*d;if(!output||capacity<required)return -2;double staged[MAX_N*MAX_D]={0};
    for(size_t src=0;src<n;++src){size_t degree=rows[src+1]-rows[src];if(degree){double scale=1.0/(double)degree;for(size_t e=rows[src];e<rows[src+1];++e){size_t dst=cols[e];for(size_t k=0;k<d;++k)staged[src*d+k]+=scale*input[xf+dst*d+k];}}}
    for(size_t q=0;q<required;++q)output[q]=staged[q];return (int64_t)required;
}
