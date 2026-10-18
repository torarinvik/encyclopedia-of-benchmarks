#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples=8,max_features=4,max_queries=4,max_input=62,max_output=25;
double add(double a,double b) noexcept {volatile double v=a+b;return v;}
double sub(double a,double b) noexcept {volatile double v=a-b;return v;}
double mul(double a,double b) noexcept {volatile double v=a*b;return v;}
bool integer(double x,int lo,int hi) noexcept {return std::isfinite(x)&&x>=lo&&x<=hi&&x==std::trunc(x);}
bool rate_ok(double x) noexcept {return x==0.25||x==0.5||x==0.75||x==1.0;}
double score(const double* w,const double* row,std::size_t len) noexcept {double s=0.0;for(std::size_t i=0;i<len;i++)s=add(s,mul(w[i],row[i]));return s;}
}

extern "C" std::int64_t perceptron_r(const double* input,std::size_t length,double* output,std::size_t capacity) noexcept {
    if(input==nullptr||length<8||length>max_input)return -1;for(std::size_t i=0;i<length;i++)if(!std::isfinite(input[i]))return -1;
    const double rate=input[0];if(!rate_ok(rate)||!integer(input[1],1,12)||!integer(input[2],2,8)||!integer(input[3],1,4))return -1;
    const auto epochs=static_cast<std::size_t>(input[1]),n=static_cast<std::size_t>(input[2]),f=static_cast<std::size_t>(input[3]);
    const std::size_t labels_at=4+n*f,qidx=labels_at+n;if(length<=qidx||!integer(input[qidx],1,4))return -1;
    const auto q=static_cast<std::size_t>(input[qidx]);if(length!=qidx+1+q*f||length>61)return -1;
    double x[max_samples*max_features],labels[max_samples],queries[max_queries*max_features];
    for(std::size_t i=0;i<n*f;i++){const double v=input[4+i];if(!integer(v,-2,2))return -1;x[i]=v;}
    for(std::size_t i=0;i<n;i++){const double v=input[labels_at+i];if(!integer(v,-2,2))return -1;labels[i]=v;}
    for(std::size_t i=0;i<q*f;i++){const double v=input[qidx+1+i];if(!integer(v,-2,2))return -1;queries[i]=v;}
    double classes[3];std::size_t class_count=0;
    for(int v=-2;v<=2;v++){bool found=false;for(std::size_t i=0;i<n;i++)if(labels[i]==v){found=true;break;}if(found)classes[class_count++]=v;}
    if(class_count<2||class_count>3)return -1;
    double rows[max_samples*(max_features+1)],query_rows[max_queries*(max_features+1)];
    for(std::size_t r=0;r<n;r++){rows[r*(f+1)]=1.0;for(std::size_t j=0;j<f;j++)rows[r*(f+1)+j+1]=x[r*f+j];}
    for(std::size_t r=0;r<q;r++){query_rows[r*(f+1)]=1.0;for(std::size_t j=0;j<f;j++)query_rows[r*(f+1)+j+1]=queries[r*f+j];}
    double weights[3][max_features+1]{};
    if(class_count==2){
        for(std::size_t e=0;e<epochs;e++)for(std::size_t r=0;r<n;r++){
            const double label=labels[r]==classes[0]?-1.0:1.0;const double value=score(weights[0],&rows[r*(f+1)],f+1);
            if(label*value<=0.0)for(std::size_t j=0;j<f+1;j++)weights[0][j]=add(weights[0][j],mul(mul(rate,label),rows[r*(f+1)+j]));
        }
    }else{
        for(std::size_t e=0;e<epochs;e++)for(std::size_t r=0;r<n;r++){
            double scores[3];for(std::size_t c=0;c<class_count;c++)scores[c]=score(weights[c],&rows[r*(f+1)],f+1);
            std::size_t predicted=0;for(std::size_t c=1;c<class_count;c++)if(scores[c]>scores[predicted])predicted=c;
            std::size_t target=0;while(target<class_count&&labels[r]!=classes[target])target++;
            if(predicted!=target)for(std::size_t j=0;j<f+1;j++){const double update=mul(rate,rows[r*(f+1)+j]);weights[target][j]=add(weights[target][j],update);weights[predicted][j]=sub(weights[predicted][j],update);}
        }
    }
    double staged[max_output];std::size_t pos=0;staged[pos++]=static_cast<double>(class_count);for(std::size_t c=0;c<class_count;c++)staged[pos++]=classes[c];
    const std::size_t parameter_count=class_count==2?f+1:class_count*(f+1);staged[pos++]=static_cast<double>(parameter_count);
    if(class_count==2){for(std::size_t j=0;j<f+1;j++)staged[pos++]=weights[0][j];}
    else for(std::size_t c=0;c<class_count;c++)for(std::size_t j=0;j<f+1;j++)staged[pos++]=weights[c][j];
    staged[pos++]=static_cast<double>(q);
    for(std::size_t r=0;r<q;r++){
        std::size_t predicted=0;
        if(class_count==2)predicted=score(weights[0],&query_rows[r*(f+1)],f+1)>=0.0?1:0;
        else{double scores[3];for(std::size_t c=0;c<class_count;c++)scores[c]=score(weights[c],&query_rows[r*(f+1)],f+1);for(std::size_t c=1;c<class_count;c++)if(scores[c]>scores[predicted])predicted=c;}
        staged[pos++]=classes[predicted];
    }
    if(output==nullptr||capacity<pos)return -2;for(std::size_t i=0;i<pos;i++)output[i]=staged[i];return static_cast<std::int64_t>(pos);
}
