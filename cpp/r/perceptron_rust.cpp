#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples=8,max_features=4,max_queries=4,max_input=62,max_output=11;
double add(double a,double b) noexcept {volatile double v=a+b;return v;}
double mul(double a,double b) noexcept {volatile double v=a*b;return v;}
bool integer(double x,int lo,int hi) noexcept {return std::isfinite(x)&&x>=lo&&x<=hi&&x==std::trunc(x);}
bool rate_ok(double x) noexcept {return x==0.25||x==0.5||x==0.75||x==1.0;}
}

extern "C" std::int64_t perceptron_rust(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept {
    if(input==nullptr||length<9||length>max_input)return -1;for(std::size_t i=0;i<length;i++)if(!std::isfinite(input[i]))return -1;
    if(!integer(input[0],0,12)||!rate_ok(input[1])||!integer(input[2],2,8)||!integer(input[3],1,4))return -1;
    const auto max_iterations=static_cast<std::size_t>(input[0]),n=static_cast<std::size_t>(input[2]),f=static_cast<std::size_t>(input[3]);
    const std::size_t labels_at=4+n*f,qidx=labels_at+n;if(length<=qidx||!integer(input[qidx],1,4))return -1;
    const auto q=static_cast<std::size_t>(input[qidx]);if(length!=qidx+1+q*f||length>61)return -1;
    double x[max_samples*max_features],labels[max_samples],queries[max_queries*max_features];
    for(std::size_t i=0;i<n*f;i++){const double v=input[4+i];if(!integer(v,-2,2))return -1;x[i]=v;}
    for(std::size_t i=0;i<n;i++){const double v=input[labels_at+i];if(v!=-1.0&&v!=1.0)return -1;labels[i]=v;}
    for(std::size_t i=0;i<q*f;i++){const double v=input[qidx+1+i];if(!integer(v,-2,2))return -1;queries[i]=v;}
    double weights[max_features]{},bias=0.0;const double rate=input[1];
    for(std::size_t e=0;e<max_iterations;e++){
        std::size_t misclassified=0;
        for(std::size_t r=0;r<n;r++){
            double score=0.0;for(std::size_t j=0;j<f;j++)score=add(score,mul(weights[j],x[r*f+j]));score=add(score,bias);
            const double prediction=score>=0.0?1.0:-1.0;
            if(prediction!=labels[r]){misclassified++;for(std::size_t j=0;j<f;j++)weights[j]=add(weights[j],mul(mul(rate,labels[r]),x[r*f+j]));bias=add(bias,mul(rate,labels[r]));}
        }
        if(misclassified==0)break;
    }
    double staged[max_output];std::size_t pos=0;staged[pos++]=static_cast<double>(f);for(std::size_t j=0;j<f;j++)staged[pos++]=weights[j];staged[pos++]=bias;staged[pos++]=static_cast<double>(q);
    for(std::size_t r=0;r<q;r++){double score=0.0;for(std::size_t j=0;j<f;j++)score=add(score,mul(weights[j],queries[r*f+j]));score=add(score,bias);staged[pos++]=score>=0.0?1.0:-1.0;}
    if(output==nullptr||capacity<pos)return -2;for(std::size_t i=0;i<pos;i++)output[i]=staged[i];return static_cast<std::int64_t>(pos);
}
