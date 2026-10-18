#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples=8,max_features=4,max_queries=4,max_input=62,max_output=12;
constexpr double initial_random[4]={0.8444218515250481,0.7579544029403025,0.420571580830845,0.25891675029296335};
double add(double a,double b) noexcept {volatile double v=a+b;return v;}
double mul(double a,double b) noexcept {volatile double v=a*b;return v;}
bool integer(double x,int lo,int hi) noexcept {return std::isfinite(x)&&x>=lo&&x<=hi&&x==std::trunc(x);}
bool rate_ok(double x) noexcept {return x==0.25||x==0.5||x==0.75||x==1.0;}
}

extern "C" std::int64_t perceptron_python(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept {
    if(input==nullptr||length<9||length>max_input)return -1;
    for(std::size_t i=0;i<length;i++)if(!std::isfinite(input[i]))return -1;
    const double rate=input[0];if(!rate_ok(rate)||!integer(input[1],1,12)||!integer(input[2],2,8)||!integer(input[3],1,4))return -1;
    const auto epochs=static_cast<std::size_t>(input[1]),n=static_cast<std::size_t>(input[2]),f=static_cast<std::size_t>(input[3]);
    const std::size_t labels_at=4+n*f,qidx=labels_at+n;
    if(length<=qidx||!integer(input[qidx],1,4))return -1;
    const auto q=static_cast<std::size_t>(input[qidx]);if(length!=qidx+1+q*f||length>61)return -1;
    double x[max_samples*max_features],y[max_samples],queries[max_queries*max_features];
    for(std::size_t i=0;i<n*f;i++){const double v=input[4+i];if(!integer(v,-2,2))return -1;x[i]=v;}
    for(std::size_t i=0;i<n;i++){const double v=input[labels_at+i];if(v!=-1.0&&v!=1.0)return -1;y[i]=v;}
    for(std::size_t i=0;i<q*f;i++){const double v=input[qidx+1+i];if(!integer(v,-2,2))return -1;queries[i]=v;}
    double w[5]={-1.0,0.0,0.0,0.0,0.0};for(std::size_t j=0;j<f;j++)w[j+1]=initial_random[j];
    std::size_t epochs_run=0;
    for(std::size_t epoch=0;epoch<epochs;epoch++){
        bool mistake=false;
        for(std::size_t row=0;row<n;row++){
            double score=mul(w[0],-1.0);for(std::size_t j=0;j<f;j++)score=add(score,mul(w[j+1],x[row*f+j]));
            const int prediction=score>=0.0?1:-1;
            if(prediction!=static_cast<int>(y[row])){
                const int error=static_cast<int>(y[row])-prediction;mistake=true;const double scale=mul(rate,static_cast<double>(error));
                w[0]=add(w[0],mul(scale,-1.0));for(std::size_t j=0;j<f;j++)w[j+1]=add(w[j+1],mul(scale,x[row*f+j]));
            }
        }
        epochs_run=epoch+1;if(!mistake)break;
    }
    double staged[max_output];std::size_t pos=0;staged[pos++]=static_cast<double>(epochs_run);staged[pos++]=static_cast<double>(f+1);
    for(std::size_t j=0;j<=f;j++)staged[pos++]=w[j];staged[pos++]=static_cast<double>(q);
    for(std::size_t row=0;row<q;row++){double score=mul(w[0],-1.0);for(std::size_t j=0;j<f;j++)score=add(score,mul(w[j+1],queries[row*f+j]));staged[pos++]=score>=0.0?1.0:-1.0;}
    if(output==nullptr||capacity<pos)return -2;for(std::size_t i=0;i<pos;i++)output[i]=staged[i];return static_cast<std::int64_t>(pos);
}
