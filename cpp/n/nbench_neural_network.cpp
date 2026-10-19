#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t nbench_neural_network(const std::int64_t *input, std::size_t length,
                                                 std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > 8) return -1;
    if (output == nullptr || capacity < 88) return -2;
    constexpr int in = 35, mid = 8, out = 8;
    constexpr double scale = 1000000.0;
    constexpr double pattern[in] = {0,1,1,1,0, 1,0,0,0,1, 1,0,0,0,1, 1,0,0,0,1, 1,0,0,0,1, 1,0,0,0,0, 0,1,1,1,0};
    constexpr double target[out] = {0,1,0,0,1,1,1,1};
    double mw[mid][in], ow[out][mid], mc[mid][in]{}, oc[out][mid]{}, mm[mid][in]{}, om[out][mid]{};
    double mout[mid]{}, oout[out]{};
    for (int n=0;n<mid;++n) for (int w=0;w<in;++w) mw[n][w]=double((n*17+w*7)%101-50)/1000.0;
    for (int n=0;n<out;++n) for (int w=0;w<mid;++w) ow[n][w]=double((n*13+w*5)%71-35)/1000.0;
    for (int pass=0;pass<input[0];++pass) {
        for (int n=0;n<mid;++n) for (int w=0;w<in;++w) { mc[n][w]=mm[n][w]; mm[n][w]=0; }
        for (int n=0;n<out;++n) for (int w=0;w<mid;++w) { oc[n][w]=om[n][w]; om[n][w]=0; }
        for (int f=0;f<2;++f) for (int n=0;n<mid;++n) {
            double sum=0; for (int w=0;w<in;++w) sum+=mw[n][w]*pattern[w];
            mout[n]=1.0/(1.0+std::exp(-sum));
        }
        for (int n=0;n<out;++n) { double sum=0; for (int w=0;w<mid;++w) sum+=ow[n][w]*mout[w]; oout[n]=1.0/(1.0+std::exp(-sum)); }
        double oe[out], me[mid];
        for (int n=0;n<out;++n) oe[n]=target[n]-oout[n];
        for (int n=0;n<mid;++n) { double sum=0; for (int i=0;i<out;++i) sum+=ow[i][n]*oe[i]; me[n]=mout[n]*(1.0-mout[n])*sum; }
        for (int n=0;n<out;++n) for (int w=0;w<mid;++w) { double d=0.09*oe[n]*mout[w]; d+=0.09*oc[n][w]; ow[n][w]+=d; om[n][w]+=d; }
        for (int n=0;n<mid;++n) for (int w=0;w<in;++w) { double d=0.09*me[n]*pattern[w]; d+=0.09*mc[n][w]; mw[n][w]+=d; mm[n][w]+=d; }
    }
    std::int64_t result[11]; result[0]=input[0];
    for (int i=0;i<out;++i) result[i+1]=static_cast<std::int64_t>(oout[i]*scale);
    double ms=0, os=0;
    for (int n=0;n<mid;++n) for (int w=0;w<in;++w) ms+=mw[n][w];
    for (int n=0;n<out;++n) for (int w=0;w<mid;++w) os+=ow[n][w];
    result[9]=static_cast<std::int64_t>(ms*scale); result[10]=static_cast<std::int64_t>(os*scale);
    for (std::size_t i=0;i<11;++i) { const std::uint64_t bits=static_cast<std::uint64_t>(result[i]); for (std::size_t b=0;b<8;++b) output[i*8+b]=static_cast<std::uint8_t>(bits>>(8*b)); }
    return 88;
}
