#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 8u
#define MAX_FEATURES 4u
#define MAX_QUERIES 4u
#define MAX_INPUT 62u
#define MAX_OUTPUT 25u
static double add(double a,double b){volatile double v=a+b;return v;}
static double sub(double a,double b){volatile double v=a-b;return v;}
static double mul(double a,double b){volatile double v=a*b;return v;}
static int integer(double x,int lo,int hi){return isfinite(x)&&x>=lo&&x<=hi&&x==trunc(x);}
static int rate_ok(double x){return x==0.25||x==0.5||x==0.75||x==1.0;}
static double score(const double* weights,const double* row,size_t length){double value=0.0;for(size_t i=0;i<length;i++)value=add(value,mul(weights[i],row[i]));return value;}

int64_t perceptron_r(const double* input,size_t length,double* output,size_t capacity){
    if(input==NULL||length<8||length>MAX_INPUT)return -1;
    for(size_t i=0;i<length;i++)if(!isfinite(input[i]))return -1;
    double rate=input[0];if(!rate_ok(rate)||!integer(input[1],1,12)||!integer(input[2],2,8)||!integer(input[3],1,4))return -1;
    size_t epochs=(size_t)input[1],n=(size_t)input[2],f=(size_t)input[3],labels_at=4+n*f,qidx=labels_at+n;
    if(length<=qidx||!integer(input[qidx],1,4))return -1;size_t q=(size_t)input[qidx];
    if(length!=qidx+1+q*f||length>61)return -1;
    double x[MAX_SAMPLES*MAX_FEATURES],labels[MAX_SAMPLES],queries[MAX_QUERIES*MAX_FEATURES];
    for(size_t i=0;i<n*f;i++){double v=input[4+i];if(!integer(v,-2,2))return -1;x[i]=v;}
    for(size_t i=0;i<n;i++){double v=input[labels_at+i];if(!integer(v,-2,2))return -1;labels[i]=v;}
    for(size_t i=0;i<q*f;i++){double v=input[qidx+1+i];if(!integer(v,-2,2))return -1;queries[i]=v;}
    double classes[3];size_t class_count=0;
    for(int value=-2;value<=2;value++){int seen=0;for(size_t i=0;i<n;i++)if(labels[i]==(double)value){seen=1;break;}if(seen)classes[class_count++]=(double)value;}
    if(class_count<2||class_count>3)return -1;
    double augmented[MAX_SAMPLES*(MAX_FEATURES+1)],aug_queries[MAX_QUERIES*(MAX_FEATURES+1)];
    for(size_t row=0;row<n;row++){augmented[row*(f+1)]=1.0;for(size_t j=0;j<f;j++)augmented[row*(f+1)+j+1]=x[row*f+j];}
    for(size_t row=0;row<q;row++){aug_queries[row*(f+1)]=1.0;for(size_t j=0;j<f;j++)aug_queries[row*(f+1)+j+1]=queries[row*f+j];}
    double weights[3][MAX_FEATURES+1]={{0.0}};
    if(class_count==2){
        for(size_t epoch=0;epoch<epochs;epoch++)for(size_t row=0;row<n;row++){
            double label=labels[row]==classes[0]?-1.0:1.0;
            double value=score(weights[0],&augmented[row*(f+1)],f+1);
            if(label*value<=0.0)for(size_t j=0;j<f+1;j++)weights[0][j]=add(weights[0][j],mul(mul(rate,label),augmented[row*(f+1)+j]));
        }
    }else{
        for(size_t epoch=0;epoch<epochs;epoch++)for(size_t row=0;row<n;row++){
            double scores[3];for(size_t c=0;c<class_count;c++)scores[c]=score(weights[c],&augmented[row*(f+1)],f+1);
            size_t predicted=0;for(size_t c=1;c<class_count;c++)if(scores[c]>scores[predicted])predicted=c;
            size_t target=0;while(target<class_count&&labels[row]!=classes[target])target++;
            if(predicted!=target)for(size_t j=0;j<f+1;j++){
                double update=mul(rate,augmented[row*(f+1)+j]);
                weights[target][j]=add(weights[target][j],update);weights[predicted][j]=sub(weights[predicted][j],update);
            }
        }
    }
    double staged[MAX_OUTPUT];size_t pos=0;staged[pos++]=(double)class_count;for(size_t c=0;c<class_count;c++)staged[pos++]=classes[c];
    size_t parameter_count=class_count==2?f+1:class_count*(f+1);staged[pos++]=(double)parameter_count;
    if(class_count==2){for(size_t j=0;j<f+1;j++)staged[pos++]=weights[0][j];}
    else for(size_t c=0;c<class_count;c++)for(size_t j=0;j<f+1;j++)staged[pos++]=weights[c][j];
    staged[pos++]=(double)q;
    for(size_t row=0;row<q;row++){
        size_t predicted;
        if(class_count==2)predicted=score(weights[0],&aug_queries[row*(f+1)],f+1)>=0.0?1:0;
        else{double scores[3];for(size_t c=0;c<class_count;c++)scores[c]=score(weights[c],&aug_queries[row*(f+1)],f+1);predicted=0;for(size_t c=1;c<class_count;c++)if(scores[c]>scores[predicted])predicted=c;}
        staged[pos++]=classes[predicted];
    }
    if(output==NULL||capacity<pos)return -2;for(size_t i=0;i<pos;i++)output[i]=staged[i];return (int64_t)pos;
}
