#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 8u
#define MAX_FEATURES 3u
#define MAX_INPUT 101u

static double add(double a,double b){volatile double v=a+b;return v;}
static double sub(double a,double b){volatile double v=a-b;return v;}
static double mul(double a,double b){volatile double v=a*b;return v;}
static double divv(double a,double b){volatile double v=a/b;return v;}

int64_t mini_batch_gradient_descent(const double *input,size_t input_length,
                                    double *output,size_t output_capacity)
{
    if(input==NULL||input_length<5||input_length>MAX_INPUT)return -1;
    for(size_t i=0;i<input_length;i++)if(!isfinite(input[i]))return -1;
    if(input[0]<1.0||input[0]>8.0||input[1]<1.0||input[1]>3.0)return -1;
    size_t samples=(size_t)input[0],features=(size_t)input[1];
    if(input[2]<1.0||input[2]>(double)samples||input[3]<0.0||input[3]>8.0)return -1;
    for(size_t i=0;i<4;i++)if(input[i]!=(double)(size_t)input[i])return -1;
    size_t batch_size=(size_t)input[2],epochs=(size_t)input[3];
    double learning_rate=input[4];if(learning_rate<0.0||learning_rate>0.25)return -1;
    size_t matrix_start=5,matrix_end=matrix_start+samples*features,targets_end=matrix_end+samples;
    if(input_length!=targets_end+epochs*samples)return -1;
    double matrix[MAX_SAMPLES*MAX_FEATURES],targets[MAX_SAMPLES];
    for(size_t i=0;i<samples*features;i++){double x=input[matrix_start+i];if(x < -10.0||x > 10.0)return -1;matrix[i]=x;}
    for(size_t i=0;i<samples;i++){double y=input[matrix_end+i];if(y < -100.0||y > 100.0)return -1;targets[i]=y;}
    size_t orders[8*MAX_SAMPLES];
    for(size_t epoch=0;epoch<epochs;epoch++){
        uint8_t seen[MAX_SAMPLES]={0};
        for(size_t pos=0;pos<samples;pos++){
            double value=input[targets_end+epoch*samples+pos];
            if(value<0.0||value>=(double)samples||value!=(double)(size_t)value)return -1;
            size_t index=(size_t)value;if(seen[index])return -1;seen[index]=1;orders[epoch*samples+pos]=index;
        }
    }
    double weights[MAX_FEATURES]={0.0},bias=0.0;
    for(size_t epoch=0;epoch<epochs;epoch++){
        for(size_t start=0;start<samples;start+=batch_size){
            size_t length=samples-start;if(length>batch_size)length=batch_size;
            double errors[MAX_SAMPLES];
            for(size_t pos=0;pos<length;pos++){
                size_t sample=orders[epoch*samples+start+pos];double prediction=0.0;
                for(size_t feature=0;feature<features;feature++){
                    double product=mul(matrix[sample*features+feature],weights[feature]);if(!isfinite(product))return -1;
                    prediction=add(prediction,product);if(!isfinite(prediction))return -1;
                }
                prediction=add(prediction,bias);if(!isfinite(prediction))return -1;
                errors[pos]=sub(prediction,targets[sample]);if(!isfinite(errors[pos]))return -1;
            }
            for(size_t feature=0;feature<features;feature++){
                double gradient=0.0;
                for(size_t pos=0;pos<length;pos++){
                    size_t sample=orders[epoch*samples+start+pos];
                    double product=mul(matrix[sample*features+feature],errors[pos]);if(!isfinite(product))return -1;
                    gradient=add(gradient,product);if(!isfinite(gradient))return -1;
                }
                double update=divv(mul(learning_rate,gradient),(double)length);
                if(!isfinite(update))return -1;
                weights[feature]=sub(weights[feature],update);if(!isfinite(weights[feature]))return -1;
            }
            double error_sum=0.0;
            for(size_t pos=0;pos<length;pos++){error_sum=add(error_sum,errors[pos]);if(!isfinite(error_sum))return -1;}
            double mean_error=divv(error_sum,(double)length);if(!isfinite(mean_error))return -1;
            double bias_update=mul(learning_rate,mean_error);if(!isfinite(bias_update))return -1;
            bias=sub(bias,bias_update);if(!isfinite(bias))return -1;
        }
    }
    double staged[MAX_FEATURES+1];for(size_t i=0;i<features;i++)staged[i]=weights[i];staged[features]=bias;
    size_t result_length=features+1;
    if(output==NULL||output_capacity<result_length)return -2;
    for(size_t i=0;i<result_length;i++)output[i]=staged[i];
    return (int64_t)result_length;
}
