#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 8u
#define MAX_FEATURES 4u
#define MAX_INPUT 35u
#define MAX_OUTPUT 34u
#define MAX_ITERATIONS 1000u
#define TOLERANCE 1e-10
#define MIN_NORM 1e-10

static double add(double a,double b){volatile double v=a+b;return v;}
static double sub(double a,double b){volatile double v=a-b;return v;}
static double mul(double a,double b){volatile double v=a*b;return v;}
static double divv(double a,double b){volatile double v=a/b;return v;}

static int power_iteration(const double *matrix,size_t n,double *eigenvalue,double *eigenvector)
{
    double vector[MAX_FEATURES], previous[MAX_FEATURES], next[MAX_FEATURES];
    for(size_t i=0;i<n;i++) vector[i]=1.0;
    int converged=0;
    for(size_t iteration=0;iteration<MAX_ITERATIONS;iteration++){
        for(size_t i=0;i<n;i++) previous[i]=vector[i];
        for(size_t i=0;i<n;i++){
            next[i]=0.0;
            for(size_t j=0;j<n;j++){
                double product=mul(matrix[i*n+j],vector[j]);
                if(!isfinite(product))return 0;
                next[i]=add(next[i],product);
                if(!isfinite(next[i]))return 0;
            }
        }
        double norm_squared=0.0;
        for(size_t i=0;i<n;i++){
            double square=mul(next[i],next[i]);
            if(!isfinite(square))return 0;
            norm_squared=add(norm_squared,square);
            if(!isfinite(norm_squared))return 0;
        }
        double norm=sqrt(norm_squared);
        if(!isfinite(norm)||norm<=MIN_NORM)return 0;
        for(size_t i=0;i<n;i++){
            vector[i]=divv(next[i],norm);
            if(!isfinite(vector[i]))return 0;
        }
        double difference=0.0;
        for(size_t i=0;i<n;i++){
            double d=fabs(sub(vector[i],previous[i]));
            if(!isfinite(d))return 0;
            if(d>difference)difference=d;
        }
        if(difference<TOLERANCE){converged=1;break;}
    }
    if(!converged)return 0;

    double numerator=0.0;
    for(size_t i=0;i<n;i++){
        double row_sum=0.0;
        for(size_t j=0;j<n;j++){
            double product=mul(matrix[i*n+j],vector[j]);
            if(!isfinite(product))return 0;
            row_sum=add(row_sum,product);
            if(!isfinite(row_sum))return 0;
        }
        double term=mul(row_sum,vector[i]);
        if(!isfinite(term))return 0;
        numerator=add(numerator,term);
        if(!isfinite(numerator))return 0;
    }
    double denominator=0.0;
    for(size_t i=0;i<n;i++){
        double square=mul(vector[i],vector[i]);
        if(!isfinite(square))return 0;
        denominator=add(denominator,square);
        if(!isfinite(denominator))return 0;
    }
    if(!isfinite(denominator)||denominator==0.0)return 0;
    *eigenvalue=divv(numerator,denominator);
    if(!isfinite(*eigenvalue))return 0;
    for(size_t i=0;i<n;i++)eigenvector[i]=vector[i];
    return 1;
}

int64_t principal_component_analysis(const double *input,size_t input_length,
                                    double *output,size_t output_capacity)
{
    if(input==NULL||input_length<3||input_length>MAX_INPUT)return -1;
    for(size_t i=0;i<input_length;i++)if(!isfinite(input[i]))return -1;
    if(input[0]<2.0||input[0]>8.0||input[0]!=(double)(size_t)input[0]||
       input[1]<2.0||input[1]>4.0||input[1]!=(double)(size_t)input[1])return -1;
    size_t samples=(size_t)input[0],features=(size_t)input[1];
    if(input[2]<1.0||input[2]>(double)features||input[2]!=(double)(size_t)input[2])return -1;
    size_t components=(size_t)input[2];
    if(input_length!=3+samples*features)return -1;
    double rows[MAX_SAMPLES*MAX_FEATURES],means[MAX_FEATURES]={0.0};
    for(size_t i=0;i<samples*features;i++){
        double x=input[3+i];if(x < -100.0||x > 100.0)return -1;rows[i]=x;
    }
    for(size_t row=0;row<samples;row++)for(size_t col=0;col<features;col++){
        means[col]=add(means[col],rows[row*features+col]);
        if(!isfinite(means[col]))return -1;
    }
    for(size_t col=0;col<features;col++){
        means[col]=divv(means[col],(double)samples);if(!isfinite(means[col]))return -1;
    }
    double centered[MAX_SAMPLES*MAX_FEATURES];
    for(size_t row=0;row<samples;row++)for(size_t col=0;col<features;col++){
        centered[row*features+col]=sub(rows[row*features+col],means[col]);
        if(!isfinite(centered[row*features+col]))return -1;
    }
    double matrix[MAX_FEATURES*MAX_FEATURES]={0.0};
    for(size_t i=0;i<features;i++)for(size_t j=i;j<features;j++){
        double cov=0.0;
        for(size_t row=0;row<samples;row++){
            double product=mul(centered[row*features+i],centered[row*features+j]);
            if(!isfinite(product))return -1;
            cov=add(cov,product);if(!isfinite(cov))return -1;
        }
        cov=divv(cov,(double)samples);if(!isfinite(cov))return -1;
        matrix[i*features+j]=cov;matrix[j*features+i]=cov;
    }
    double vectors[MAX_FEATURES*MAX_FEATURES]={0.0};
    for(size_t component=0;component<components;component++){
        double eigenvalue,vector[MAX_FEATURES];
        if(!power_iteration(matrix,features,&eigenvalue,vector))return -1;
        for(size_t i=0;i<features;i++)vectors[component*features+i]=vector[i];
        for(size_t i=0;i<features;i++)for(size_t j=0;j<features;j++){
            double term=mul(mul(eigenvalue,vector[i]),vector[j]);
            if(!isfinite(term))return -1;
            matrix[i*features+j]=sub(matrix[i*features+j],term);
            if(!isfinite(matrix[i*features+j]))return -1;
        }
    }
    double staged[MAX_OUTPUT]={0.0};staged[0]=(double)samples;staged[1]=(double)components;
    size_t pos=2;
    for(size_t row=0;row<samples;row++)for(size_t component=0;component<components;component++){
        double score=0.0;
        for(size_t feature=0;feature<features;feature++){
            double product=mul(vectors[component*features+feature],centered[row*features+feature]);
            if(!isfinite(product))return -1;
            score=add(score,product);if(!isfinite(score))return -1;
        }
        staged[pos++]=score;
    }
    if(output==NULL||output_capacity<pos)return -2;
    for(size_t i=0;i<pos;i++)output[i]=staged[i];
    return (int64_t)pos;
}
