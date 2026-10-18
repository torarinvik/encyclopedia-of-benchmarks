#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 8u
#define MAX_FEATURES 4u
#define MAX_QUERIES 4u
#define MAX_INPUT 62u
#define MAX_OUTPUT 11u
static double add(double a,double b){volatile double v=a+b;return v;}
static double mul(double a,double b){volatile double v=a*b;return v;}
static int integer(double x,int lo,int hi){return isfinite(x)&&x>=lo&&x<=hi&&x==trunc(x);}
static int rate_ok(double x){return x==0.25||x==0.5||x==0.75||x==1.0;}

int64_t perceptron_rust(const double* input,size_t length,double* output,size_t capacity){
    if(input==NULL||length<9||length>MAX_INPUT)return -1;
    for(size_t i=0;i<length;i++)if(!isfinite(input[i]))return -1;
    if(!integer(input[0],0,12)||!rate_ok(input[1])||!integer(input[2],2,8)||!integer(input[3],1,4))return -1;
    size_t max_iterations=(size_t)input[0],n=(size_t)input[2],f=(size_t)input[3],labels_at=4+n*f,qidx=labels_at+n;
    if(length<=qidx||!integer(input[qidx],1,4))return -1;size_t q=(size_t)input[qidx];
    if(length!=qidx+1+q*f||length>61)return -1;
    double x[MAX_SAMPLES*MAX_FEATURES],labels[MAX_SAMPLES],queries[MAX_QUERIES*MAX_FEATURES];
    for(size_t i=0;i<n*f;i++){double v=input[4+i];if(!integer(v,-2,2))return -1;x[i]=v;}
    for(size_t i=0;i<n;i++){double v=input[labels_at+i];if(v!=-1.0&&v!=1.0)return -1;labels[i]=v;}
    for(size_t i=0;i<q*f;i++){double v=input[qidx+1+i];if(!integer(v,-2,2))return -1;queries[i]=v;}
    double weights[MAX_FEATURES]={0.0},bias=0.0;
    for(size_t iteration=0;iteration<max_iterations;iteration++){
        int misclassified=0;
        for(size_t row=0;row<n;row++){
            double score=0.0;for(size_t j=0;j<f;j++)score=add(score,mul(weights[j],x[row*f+j]));score=add(score,bias);
            double prediction=score>=0.0?1.0:-1.0;
            if(prediction!=labels[row]){misclassified++;for(size_t j=0;j<f;j++)weights[j]=add(weights[j],mul(mul(input[1],labels[row]),x[row*f+j]));bias=add(bias,mul(input[1],labels[row]));}
        }
        if(misclassified==0)break;
    }
    double staged[MAX_OUTPUT];size_t pos=0;staged[pos++]=(double)f;for(size_t j=0;j<f;j++)staged[pos++]=weights[j];staged[pos++]=bias;staged[pos++]=(double)q;
    for(size_t row=0;row<q;row++){double score=0.0;for(size_t j=0;j<f;j++)score=add(score,mul(weights[j],queries[row*f+j]));score=add(score,bias);staged[pos++]=score>=0.0?1.0:-1.0;}
    if(output==NULL||capacity<pos)return -2;for(size_t i=0;i<pos;i++)output[i]=staged[i];return (int64_t)pos;
}
