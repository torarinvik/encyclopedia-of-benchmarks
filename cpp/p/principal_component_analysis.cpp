#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples=8,max_features=4,max_input=35,max_output=34,max_iterations=1000;
constexpr double tolerance=1e-10,min_norm=1e-10;
double add(double a,double b) noexcept { volatile double v=a+b;return v; }
double sub(double a,double b) noexcept { volatile double v=a-b;return v; }
double mul(double a,double b) noexcept { volatile double v=a*b;return v; }
double divv(double a,double b) noexcept { volatile double v=a/b;return v; }
bool power_iteration(const double* matrix,std::size_t n,double& eigenvalue,double* eigenvector) noexcept {
    double vector[max_features],previous[max_features],next[max_features];
    for(std::size_t i=0;i<n;i++)vector[i]=1.0;
    bool converged=false;
    for(std::size_t iteration=0;iteration<max_iterations;iteration++){
        for(std::size_t i=0;i<n;i++)previous[i]=vector[i];
        for(std::size_t i=0;i<n;i++){
            next[i]=0.0;
            for(std::size_t j=0;j<n;j++){
                double product=mul(matrix[i*n+j],vector[j]);if(!std::isfinite(product))return false;
                next[i]=add(next[i],product);if(!std::isfinite(next[i]))return false;
            }
        }
        double norm_squared=0.0;
        for(std::size_t i=0;i<n;i++){
            double square=mul(next[i],next[i]);if(!std::isfinite(square))return false;
            norm_squared=add(norm_squared,square);if(!std::isfinite(norm_squared))return false;
        }
        double norm=std::sqrt(norm_squared);if(!std::isfinite(norm)||norm<=min_norm)return false;
        for(std::size_t i=0;i<n;i++){vector[i]=divv(next[i],norm);if(!std::isfinite(vector[i]))return false;}
        double difference=0.0;
        for(std::size_t i=0;i<n;i++){
            double d=std::fabs(sub(vector[i],previous[i]));if(!std::isfinite(d))return false;
            if(d>difference)difference=d;
        }
        if(difference<tolerance){converged=true;break;}
    }
    if(!converged)return false;
    double numerator=0.0;
    for(std::size_t i=0;i<n;i++){
        double row_sum=0.0;
        for(std::size_t j=0;j<n;j++){
            double product=mul(matrix[i*n+j],vector[j]);if(!std::isfinite(product))return false;
            row_sum=add(row_sum,product);if(!std::isfinite(row_sum))return false;
        }
        double term=mul(row_sum,vector[i]);if(!std::isfinite(term))return false;
        numerator=add(numerator,term);if(!std::isfinite(numerator))return false;
    }
    double denominator=0.0;
    for(std::size_t i=0;i<n;i++){
        double square=mul(vector[i],vector[i]);if(!std::isfinite(square))return false;
        denominator=add(denominator,square);if(!std::isfinite(denominator))return false;
    }
    if(!std::isfinite(denominator)||denominator==0.0)return false;
    eigenvalue=divv(numerator,denominator);if(!std::isfinite(eigenvalue))return false;
    for(std::size_t i=0;i<n;i++)eigenvector[i]=vector[i];
    return true;
}
}

extern "C" std::int64_t principal_component_analysis(const double* input,std::size_t input_length,
    double* output,std::size_t output_capacity) noexcept {
    if(input==nullptr||input_length<3||input_length>max_input)return -1;
    for(std::size_t i=0;i<input_length;i++)if(!std::isfinite(input[i]))return -1;
    if(input[0]<2.0||input[0]>8.0||input[0]!=static_cast<double>(static_cast<std::size_t>(input[0]))||
       input[1]<2.0||input[1]>4.0||input[1]!=static_cast<double>(static_cast<std::size_t>(input[1])))return -1;
    std::size_t samples=static_cast<std::size_t>(input[0]),features=static_cast<std::size_t>(input[1]);
    if(input[2]<1.0||input[2]>static_cast<double>(features)||input[2]!=static_cast<double>(static_cast<std::size_t>(input[2])))return -1;
    std::size_t components=static_cast<std::size_t>(input[2]);
    if(input_length!=3+samples*features)return -1;
    double rows[max_samples*max_features],means[max_features]={};
    for(std::size_t i=0;i<samples*features;i++){double x=input[3+i];if(x < -100.0||x > 100.0)return -1;rows[i]=x;}
    for(std::size_t row=0;row<samples;row++)for(std::size_t col=0;col<features;col++){
        means[col]=add(means[col],rows[row*features+col]);if(!std::isfinite(means[col]))return -1;
    }
    for(std::size_t col=0;col<features;col++){means[col]=divv(means[col],static_cast<double>(samples));if(!std::isfinite(means[col]))return -1;}
    double centered[max_samples*max_features];
    for(std::size_t row=0;row<samples;row++)for(std::size_t col=0;col<features;col++){
        centered[row*features+col]=sub(rows[row*features+col],means[col]);if(!std::isfinite(centered[row*features+col]))return -1;
    }
    double matrix[max_features*max_features]={};
    for(std::size_t i=0;i<features;i++)for(std::size_t j=i;j<features;j++){
        double cov=0.0;
        for(std::size_t row=0;row<samples;row++){
            double product=mul(centered[row*features+i],centered[row*features+j]);if(!std::isfinite(product))return -1;
            cov=add(cov,product);if(!std::isfinite(cov))return -1;
        }
        cov=divv(cov,static_cast<double>(samples));if(!std::isfinite(cov))return -1;
        matrix[i*features+j]=cov;matrix[j*features+i]=cov;
    }
    double vectors[max_features*max_features]={};
    for(std::size_t component=0;component<components;component++){
        double eigenvalue,vector[max_features];if(!power_iteration(matrix,features,eigenvalue,vector))return -1;
        for(std::size_t i=0;i<features;i++)vectors[component*features+i]=vector[i];
        for(std::size_t i=0;i<features;i++)for(std::size_t j=0;j<features;j++){
            double term=mul(mul(eigenvalue,vector[i]),vector[j]);if(!std::isfinite(term))return -1;
            matrix[i*features+j]=sub(matrix[i*features+j],term);if(!std::isfinite(matrix[i*features+j]))return -1;
        }
    }
    double staged[max_output]={};staged[0]=static_cast<double>(samples);staged[1]=static_cast<double>(components);std::size_t pos=2;
    for(std::size_t row=0;row<samples;row++)for(std::size_t component=0;component<components;component++){
        double score=0.0;
        for(std::size_t feature=0;feature<features;feature++){
            double product=mul(vectors[component*features+feature],centered[row*features+feature]);if(!std::isfinite(product))return -1;
            score=add(score,product);if(!std::isfinite(score))return -1;
        }
        staged[pos++]=score;
    }
    if(output==nullptr||output_capacity<pos)return -2;
    for(std::size_t i=0;i<pos;i++)output[i]=staged[i];
    return static_cast<std::int64_t>(pos);
}
