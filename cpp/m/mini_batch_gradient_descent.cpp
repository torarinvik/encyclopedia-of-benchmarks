#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples=8,max_features=3,max_input=101;
double add(double a,double b) noexcept { volatile double v=a+b;return v; }
double sub(double a,double b) noexcept { volatile double v=a-b;return v; }
double mul(double a,double b) noexcept { volatile double v=a*b;return v; }
double divv(double a,double b) noexcept { volatile double v=a/b;return v; }
}

extern "C" std::int64_t mini_batch_gradient_descent(const double* input,std::size_t input_length,
    double* output,std::size_t output_capacity) noexcept {
    if(input==nullptr||input_length<5||input_length>max_input)return -1;
    for(std::size_t i=0;i<input_length;i++)if(!std::isfinite(input[i]))return -1;
    if(input[0]<1.0||input[0]>8.0||input[1]<1.0||input[1]>3.0)return -1;
    std::size_t samples=static_cast<std::size_t>(input[0]),features=static_cast<std::size_t>(input[1]);
    if(input[2]<1.0||input[2]>static_cast<double>(samples)||input[3]<0.0||input[3]>8.0)return -1;
    for(std::size_t i=0;i<4;i++)if(input[i]!=static_cast<double>(static_cast<std::size_t>(input[i])))return -1;
    std::size_t batch_size=static_cast<std::size_t>(input[2]),epochs=static_cast<std::size_t>(input[3]);
    double learning_rate=input[4];if(learning_rate<0.0||learning_rate>0.25)return -1;
    std::size_t matrix_start=5,matrix_end=matrix_start+samples*features,targets_end=matrix_end+samples;
    if(input_length!=targets_end+epochs*samples)return -1;
    double matrix[max_samples*max_features],targets[max_samples];
    for(std::size_t i=0;i<samples*features;i++){double x=input[matrix_start+i];if(x < -10.0||x > 10.0)return -1;matrix[i]=x;}
    for(std::size_t i=0;i<samples;i++){double y=input[matrix_end+i];if(y < -100.0||y > 100.0)return -1;targets[i]=y;}
    std::size_t orders[8*max_samples];
    for(std::size_t epoch=0;epoch<epochs;epoch++){
        bool seen[max_samples]={false};
        for(std::size_t pos=0;pos<samples;pos++){
            double value=input[targets_end+epoch*samples+pos];
            if(value<0.0||value>=static_cast<double>(samples)||value!=static_cast<double>(static_cast<std::size_t>(value)))return -1;
            std::size_t index=static_cast<std::size_t>(value);if(seen[index])return -1;seen[index]=true;orders[epoch*samples+pos]=index;
        }
    }
    double weights[max_features]={},bias=0.0;
    for(std::size_t epoch=0;epoch<epochs;epoch++)for(std::size_t start=0;start<samples;start+=batch_size){
        std::size_t length=samples-start;if(length>batch_size)length=batch_size;
        double errors[max_samples];
        for(std::size_t pos=0;pos<length;pos++){
            std::size_t sample=orders[epoch*samples+start+pos];double prediction=0.0;
            for(std::size_t feature=0;feature<features;feature++){
                double product=mul(matrix[sample*features+feature],weights[feature]);if(!std::isfinite(product))return -1;
                prediction=add(prediction,product);if(!std::isfinite(prediction))return -1;
            }
            prediction=add(prediction,bias);if(!std::isfinite(prediction))return -1;
            errors[pos]=sub(prediction,targets[sample]);if(!std::isfinite(errors[pos]))return -1;
        }
        for(std::size_t feature=0;feature<features;feature++){
            double gradient=0.0;
            for(std::size_t pos=0;pos<length;pos++){
                std::size_t sample=orders[epoch*samples+start+pos];
                double product=mul(matrix[sample*features+feature],errors[pos]);if(!std::isfinite(product))return -1;
                gradient=add(gradient,product);if(!std::isfinite(gradient))return -1;
            }
            double update=divv(mul(learning_rate,gradient),static_cast<double>(length));if(!std::isfinite(update))return -1;
            weights[feature]=sub(weights[feature],update);if(!std::isfinite(weights[feature]))return -1;
        }
        double error_sum=0.0;
        for(std::size_t pos=0;pos<length;pos++){error_sum=add(error_sum,errors[pos]);if(!std::isfinite(error_sum))return -1;}
        double mean_error=divv(error_sum,static_cast<double>(length));if(!std::isfinite(mean_error))return -1;
        double bias_update=mul(learning_rate,mean_error);if(!std::isfinite(bias_update))return -1;
        bias=sub(bias,bias_update);if(!std::isfinite(bias))return -1;
    }
    double staged[max_features+1];for(std::size_t i=0;i<features;i++)staged[i]=weights[i];staged[features]=bias;
    std::size_t result_length=features+1;
    if(output==nullptr||output_capacity<result_length)return -2;
    for(std::size_t i=0;i<result_length;i++)output[i]=staged[i];
    return static_cast<std::int64_t>(result_length);
}
