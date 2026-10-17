#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 64, max_input_length = 66;
bool less_float(float left, float right) { return left < right || (left == 0.0f && right == 0.0f && std::signbit(left) && !std::signbit(right)); }
void push_max(float* heap, std::size_t& count, float value) { std::size_t p=count++; while(p>0&&less_float(heap[(p-1)/2],value)){auto parent=(p-1)/2;heap[p]=heap[parent];p=parent;}heap[p]=value; }
float pop_max(float* heap, std::size_t& count) { float result=heap[0],value=heap[--count];if(count==0)return result;std::size_t p=0;while(2*p+1<count){std::size_t child=2*p+1;if(child+1<count&&less_float(heap[child],heap[child+1]))++child;if(!less_float(value,heap[child]))break;heap[p]=heap[child];p=child;}heap[p]=value;return result; }
void push_min(float* heap, std::size_t& count, float value) { std::size_t p=count++; while(p>0&&less_float(value,heap[(p-1)/2])){auto parent=(p-1)/2;heap[p]=heap[parent];p=parent;}heap[p]=value; }
float pop_min(float* heap, std::size_t& count) { float result=heap[0],value=heap[--count];if(count==0)return result;std::size_t p=0;while(2*p+1<count){std::size_t child=2*p+1;if(child+1<count&&less_float(heap[child+1],heap[child]))++child;if(!less_float(heap[child],value))break;heap[p]=heap[child];p=child;}heap[p]=value;return result; }
}

extern "C" std::int64_t median_of_running_array_float(const double* input, std::size_t length,
                                                       double* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const double count_value=input[0];
    if (!std::isfinite(count_value)||count_value<1.0||count_value>max_count||std::trunc(count_value)!=count_value||length!=1+static_cast<std::size_t>(count_value)) return -1;
    const auto count=static_cast<std::size_t>(count_value); float lower[max_count],upper[max_count],medians[max_count];std::size_t lc=0,uc=0;
    for(std::size_t i=0;i<count;++i){const double sample=input[i+1];if(!std::isfinite(sample)||sample < -1000000.0||sample>1000000.0)return -1;const float x=static_cast<float>(sample);if(static_cast<double>(x)!=sample||(sample==0.0&&std::signbit(x)!=std::signbit(sample)))return -1;
        if(uc>0&&less_float(x,upper[0]))push_max(lower,lc,x);else push_min(upper,uc,x);
        if(lc>uc+1)push_min(upper,uc,pop_max(lower,lc));else if(uc>lc+1)push_max(lower,lc,pop_min(upper,uc));
        if(lc>uc)medians[i]=lower[0];else if(uc>lc)medians[i]=upper[0];else{volatile float sum=lower[0]+upper[0];medians[i]=sum/2.0f;}}
    if(output==nullptr||capacity<count)return -2;for(std::size_t i=0;i<count;++i)output[i]=static_cast<double>(medians[i]);return static_cast<std::int64_t>(count);
}
