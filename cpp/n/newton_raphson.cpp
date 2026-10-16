#include <cstddef>
#include <cstdint>
extern "C" double newton_raphson(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1.0e300;
    const auto radicand=values[0], quarters=values[1];
    if (radicand<2 || radicand>4 || quarters<4 || quarters>8) return -1.0e300;
    double x=static_cast<double>(quarters)/4.0;
    for(int i=0;i<8;i++) x=0.5*(x+static_cast<double>(radicand)/x);
    return x;
}
