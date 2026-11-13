#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 5;
bool integer_field(double value, int low, int high, int& decoded) noexcept {
    if (!std::isfinite(value) || value < low || value > high || std::trunc(value) != value) return false;
    decoded = static_cast<int>(value);
    return true;
}
double integrand(int id, double x) noexcept {
    if (id == 0) return std::exp(x);
    if (id == 1) return x*x*x*x*x;
    if (id == 2) return 1.0/(1.0+x*x);
    return std::cos(x);
}
double romberg(int id, double a, double b, int levels) noexcept {
    if (a == b) return 0.0;
    double previous[9]{};
    previous[0] = (b-a)*(integrand(id,a)+integrand(id,b))*0.5;
    for (int level=1; level<=levels; ++level) {
        const int interval_count = 1 << level;
        const double spacing = (b-a)/static_cast<double>(interval_count);
        double added = 0.0;
        for (int index=1; index<interval_count; index+=2)
            added += integrand(id,a+static_cast<double>(index)*spacing);
        double current[9]{};
        current[0] = previous[0]*0.5+spacing*added;
        double factor=4.0;
        for (int order=1; order<=level; ++order) {
            current[order]=current[order-1]+(current[order-1]-previous[order-1])/(factor-1.0);
            factor*=4.0;
        }
        for (int order=0; order<=level; ++order) previous[order]=current[order];
    }
    return previous[levels];
}
}

extern "C" std::int64_t romberg_integration(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    if (input==nullptr || input_length!=4 || input_length>max_input_length) return -1;
    int id,a_micro,b_micro,levels;
    if (!integer_field(input[0],0,3,id) || !integer_field(input[1],-1000000,1000000,a_micro) ||
        !integer_field(input[2],-1000000,1000000,b_micro) || !integer_field(input[3],3,8,levels) ||
        a_micro>b_micro) return -1;
    if (output==nullptr || output_capacity<1) return -2;
    const double result=romberg(id,a_micro/1000000.0,b_micro/1000000.0,levels);
    if (!std::isfinite(result)) return -1;
    output[0]=result;
    return 1;
}
