/* Clean-room deterministic projection of GraphAIBench's three-hop sampler. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_N 8
#define MAX_M 24
#define MAX_R 4
#define MAX_INPUT (4+MAX_N+MAX_M+22*MAX_R)
int64_t graphai_frontier_sampler(const double *input,size_t length,double *output,size_t capacity){
    if(!input||length<3||length>MAX_INPUT)return -1;for(size_t q=0;q<length;++q)if(!isfinite(input[q]))return -1;
    double nv=input[0],mv=input[1],rv=input[2];if(trunc(nv)!=nv||trunc(mv)!=mv||trunc(rv)!=rv||nv<1||nv>MAX_N||mv<0||mv>MAX_M||rv<1||rv>MAX_R)return -1;
    size_t n=(size_t)nv,m=(size_t)mv,r=(size_t)rv,required=22*r;if(length!=4+n+m+22*r)return -1;
    size_t root_at=3,row_at=root_at+r,col_at=row_at+n+1,choice_at=col_at+m;
    size_t rows[MAX_N+1],cols[MAX_M],front[MAX_R*12],next[MAX_R*12];double staged[MAX_R*22];
    for(size_t i=0;i<r;++i){double x=input[root_at+i];if(trunc(x)!=x||x<0||x>=n)return -1;front[i]=(size_t)x;staged[i]=x;}
    if(input[row_at]!=0||input[col_at-1]!=(double)m)return -1;
    for(size_t i=0;i<=n;++i){double x=input[row_at+i];if(trunc(x)!=x||x<0||x>m)return -1;rows[i]=(size_t)x;if(i&&rows[i]<rows[i-1])return -1;}
    for(size_t e=0;e<m;++e){double x=input[col_at+e];if(trunc(x)!=x||x<0||x>=n)return -1;cols[e]=(size_t)x;}
    if(!output||capacity<required)return -2;
    size_t fanouts[3]={3,2,2},front_size=r,choice=0,out_at=r;
    for(size_t round=0;round<3;++round){size_t next_size=front_size*fanouts[round];
        for(size_t i=0;i<front_size;++i){size_t parent=front[i],begin=rows[parent],degree=rows[parent+1]-begin;if(degree==0)return -1;
            for(size_t j=0;j<fanouts[round];++j){double x=input[choice_at+choice++];if(trunc(x)!=x||x<0||x>=degree)return -1;size_t v=cols[begin+(size_t)x];next[i*fanouts[round]+j]=v;staged[out_at++]=(double)v;}
        }
        for(size_t i=0;i<next_size;++i)front[i]=next[i];front_size=next_size;
    }
    if(choice!=21*r||out_at!=required)return -1;for(size_t q=0;q<required;++q)output[q]=staged[q];return (int64_t)required;
}
