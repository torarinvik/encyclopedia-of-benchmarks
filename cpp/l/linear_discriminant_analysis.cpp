#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_classes = 4, max_samples = 16, max_input = 22;
constexpr double min_margin = 1e-8;
}
extern "C" std::int64_t linear_discriminant_analysis(const double* input, std::size_t input_length,
    double* output, std::size_t capacity) {
    if (!input || input_length == 0 || input_length > max_input) return -1;
    const double class_value = input[0];
    if (!std::isfinite(class_value) || class_value < 2 || class_value > 4 || std::trunc(class_value) != class_value) return -1;
    const auto class_count = static_cast<std::size_t>(class_value);
    if (input_length < 1 + class_count) return -1;
    std::array<std::size_t,max_classes> counts{};
    std::size_t total_count = 0;
    for (std::size_t k=0;k<class_count;++k) {
        const double value = input[1+k];
        if (!std::isfinite(value) || value < 2 || value > 6 || std::trunc(value) != value) return -1;
        counts[k]=static_cast<std::size_t>(value); total_count+=counts[k];
    }
    if (total_count>max_samples || input_length!=1+class_count+total_count) return -1;
    std::array<std::array<double,6>,max_classes> groups{};
    std::array<double,max_classes> means{};
    std::size_t offset=1+class_count;
    for(std::size_t k=0;k<class_count;++k){
        double sum=0;
        for(std::size_t j=0;j<counts[k];++j){const double x=input[offset++];if(!std::isfinite(x)||x < -32||x > 32||std::trunc(x)!=x)return -1;groups[k][j]=x;sum+=x;}
        means[k]=sum/static_cast<double>(counts[k]);
        if(std::trunc(means[k])!=means[k])return -1;
    }
    double squared_sum=0;
    for(std::size_t k=0;k<class_count;++k)for(std::size_t j=0;j<counts[k];++j){const double d=groups[k][j]-means[k];squared_sum+=d*d;}
    const double variance=(1.0/static_cast<double>(total_count-class_count))*squared_sum;
    if(!std::isfinite(variance)||variance<=0)return -1;
    std::array<double,max_classes> priors{};
    for(std::size_t k=0;k<class_count;++k)priors[k]=static_cast<double>(counts[k])/static_cast<double>(total_count);
    std::array<double,max_samples> staged{};std::size_t n=0;
    for(std::size_t group=0;group<class_count;++group)for(std::size_t j=0;j<counts[group];++j){
        const double x=groups[group][j];double best=-INFINITY,second=-INFINITY;std::size_t winner=0;
        for(std::size_t k=0;k<class_count;++k){const double score=x*(means[k]/variance)-(means[k]*means[k]/(2.0*variance))+std::log(priors[k]);if(score>best){second=best;best=score;winner=k;}else if(score>second)second=score;}
        if(!std::isfinite(best)||best-second<min_margin)return -1;staged[n++]=static_cast<double>(winner);
    }
    if(!output||capacity<n)return -2;for(std::size_t i=0;i<n;++i)output[i]=staged[i];return static_cast<std::int64_t>(n);
}
