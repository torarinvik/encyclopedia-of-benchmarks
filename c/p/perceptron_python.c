#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 8u
#define MAX_FEATURES 4u
#define MAX_QUERIES 4u
#define MAX_INPUT 62u
#define MAX_OUTPUT 12u
static const double initial_random[4]={0.8444218515250481,0.7579544029403025,0.420571580830845,0.25891675029296335};
static double add(double a,double b){volatile double v=a+b;return v;}
static double mul(double a,double b){volatile double v=a*b;return v;}
static int integer(double x,int lo,int hi){return isfinite(x)&&x>=lo&&x<=hi&&x==trunc(x);}
static int valid_rate(double x){return x==0.25||x==0.5||x==0.75||x==1.0;}

int64_t perceptron_python(const double* input,size_t length,double* output,size_t capacity){
    if(input==NULL||length<9||length>MAX_INPUT)return -1;
    for(size_t i=0;i<length;i++)if(!isfinite(input[i]))return -1;
    double rate=input[0];if(!valid_rate(rate)||!integer(input[1],1,12)||!integer(input[2],2,8)||!integer(input[3],1,4))return -1;
    size_t epochs=(size_t)input[1],n=(size_t)input[2],f=(size_t)input[3],labels_at=4+n*f,qidx=labels_at+n;
    if(length<=qidx||!integer(input[qidx],1,4))return -1;
    size_t q=(size_t)input[qidx];if(length!=qidx+1+q*f||length>61)return -1;
    double x[MAX_SAMPLES*MAX_FEATURES],y[MAX_SAMPLES],queries[MAX_QUERIES*MAX_FEATURES];
    for(size_t i=0;i<n*f;i++){double v=input[4+i];if(!integer(v,-2,2))return -1;x[i]=v;}
    for(size_t i=0;i<n;i++){double v=input[labels_at+i];if(v!=-1.0&&v!=1.0)return -1;y[i]=v;}
    for(size_t i=0;i<q*f;i++){double v=input[qidx+1+i];if(!integer(v,-2,2))return -1;queries[i]=v;}
    double w[5]={-1.0,0.0,0.0,0.0,0.0};for(size_t j=0;j<f;j++)w[j+1]=initial_random[j];
    size_t epochs_run=0;
    for(size_t epoch=0;epoch<epochs;epoch++){
        int has_mistake=0;
        for(size_t row=0;row<n;row++){
            double score=mul(w[0],-1.0);
            for(size_t j=0;j<f;j++)score=add(score,mul(w[j+1],x[row*f+j]));
            int prediction=score>=0.0?1:-1;
            if(prediction!=(int)y[row]){
                int error=(int)y[row]-prediction;has_mistake=1;
                double scale=mul(rate,(double)error);
                w[0]=add(w[0],mul(scale,-1.0));
                for(size_t j=0;j<f;j++)w[j+1]=add(w[j+1],mul(scale,x[row*f+j]));
            }
        }
        epochs_run=epoch+1;if(!has_mistake)break;
    }
    double staged[MAX_OUTPUT];size_t pos=0;staged[pos++]=(double)epochs_run;staged[pos++]=(double)(f+1);
    for(size_t j=0;j<=f;j++)staged[pos++]=w[j];staged[pos++]=(double)q;
    for(size_t row=0;row<q;row++){
        double score=mul(w[0],-1.0);for(size_t j=0;j<f;j++)score=add(score,mul(w[j+1],queries[row*f+j]));
        staged[pos++]=score>=0.0?1.0:-1.0;
    }
    if(output==NULL||capacity<pos)return -2;for(size_t i=0;i<pos;i++)output[i]=staged[i];return (int64_t)pos;
}
