/* Clean-room bounded GraphAIBench collaborative-filtering SGD sweep. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_N 8
#define MAX_M 24
#define MAX_K 4
#define MAX_INPUT (7+MAX_N+2*MAX_M+MAX_N*MAX_K)
int64_t graphai_cf_sgd_sweep(const double *input,size_t length,double *output,size_t capacity){
    if(!input||length<6||length>MAX_INPUT)return -1;for(size_t q=0;q<length;++q)if(!isfinite(input[q]))return -1;
    double uv=input[0],iv=input[1],mv=input[2],kv=input[3];if(trunc(uv)!=uv||trunc(iv)!=iv||trunc(mv)!=mv||trunc(kv)!=kv||uv<1||uv>7||iv<1||iv>7||mv<0||mv>MAX_M||kv<1||kv>MAX_K)return -1;
    size_t users=(size_t)uv,items=(size_t)iv,n=users+items,m=(size_t)mv,k=(size_t)kv;double lambda=input[4],step=input[5];
    if(n>MAX_N||lambda<0||lambda>1||step<0||step>0.01||length!=7+n+2*m+n*k)return -1;
    size_t rp=6,ci=rp+n+1,ra=ci+m,la=ra+m;if(input[rp]!=0||input[ci-1]!=(double)m)return -1;
    size_t rows[MAX_N+1],cols[MAX_M];for(size_t i=0;i<=n;++i){double x=input[rp+i];if(trunc(x)!=x||x<0||x>m)return -1;rows[i]=(size_t)x;if(i&&rows[i]<rows[i-1])return -1;}
    for(size_t u=users;u<n;++u)if(rows[u]!=rows[u+1])return -1;
    for(size_t e=0;e<m;++e){double x=input[ci+e];if(trunc(x)!=x||x<users||x>=n)return -1;cols[e]=(size_t)x;}
    for(size_t e=0;e<m;++e)if(input[ra+e]<-4||input[ra+e]>4)return -1;
    for(size_t q=0;q<n*k;++q)if(input[la+q]<-2||input[la+q]>2)return -1;
    size_t required=n*k;if(!output||capacity<required)return -2;double error[MAX_N*MAX_K]={0},staged[MAX_N*MAX_K]={0};
    for(size_t u=0;u<users;++u)for(size_t e=rows[u];e<rows[u+1];++e){size_t v=cols[e];double estimate=0;for(size_t j=0;j<k;++j)estimate+=input[la+u*k+j]*input[la+v*k+j];double delta=input[ra+e]-estimate;for(size_t j=0;j<k;++j)error[u*k+j]+=input[la+v*k+j]*delta;}
    for(size_t v=0;v<n;++v)for(size_t j=0;j<k;++j){size_t q=v*k+j;staged[q]=input[la+q]+step*(-lambda*input[la+q]+error[q]);}
    for(size_t q=0;q<required;++q)output[q]=staged[q];return (int64_t)required;
}
