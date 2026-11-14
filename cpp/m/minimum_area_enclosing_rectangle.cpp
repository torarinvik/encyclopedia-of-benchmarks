#include <array>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <utility>
#include <vector>

extern "C" std::int64_t minimum_area_enclosing_rectangle(const std::int64_t* input, std::size_t length,
                                                         std::uint8_t* output, std::size_t capacity) {
    if (!input || length<7 || length>34 || input[0]<3 || input[0]>16) return -1;
    const auto n=static_cast<std::size_t>(input[0]);
    if (length!=1+2*n) return -1;
    std::vector<std::pair<std::int64_t,std::int64_t>> points;
    points.reserve(n);
    for (std::size_t i=0; i<n; ++i) {
        const auto x=input[1+2*i], y=input[2+2*i];
        if (x< -100 || x>100 || y< -100 || y>100) return -1;
        points.emplace_back(x,y);
    }
    for (std::size_t i=0; i<n; ++i) {
        const auto next=(i+1)%n;
        const auto [ax,ay]=points[i];
        const auto dx=points[next].first-ax, dy=points[next].second-ay;
        for (std::size_t j=0; j<n; ++j)
            if (j!=i && j!=next && dx*(points[j].second-ay)-dy*(points[j].first-ax)<=0) return -1;
    }
    auto project=[&](std::size_t index,std::int64_t dx,std::int64_t dy,int axis) {
        const auto [x,y]=points[index];
        return axis==2 ? dx*y-dy*x : dx*x+dy*y;
    };
    const auto first_dx=points[1].first-points[0].first, first_dy=points[1].second-points[0].second;
    std::array<std::size_t,3> support{};
    for (std::size_t i=1; i<n; ++i) for (int axis=0; axis<3; ++axis) {
        const auto current=project(support[axis],first_dx,first_dy,axis);
        const auto candidate=project(i,first_dx,first_dy,axis);
        if ((axis==1 && candidate<current) || (axis!=1 && candidate>current)) support[axis]=i;
    }
    std::int64_t best_num=0,best_den=1;
    for (std::size_t i=0; i<n; ++i) {
        const auto [ax,ay]=points[i];
        const auto next=(i+1)%n;
        const auto dx=points[next].first-ax, dy=points[next].second-ay;
        for (int axis=0; axis<3; ++axis) for (std::size_t steps=0; steps<n; ++steps) {
            const auto following=(support[axis]+1)%n;
            const auto current=project(support[axis],dx,dy,axis);
            const auto candidate=project(following,dx,dy,axis);
            if ((axis==1 && candidate<=current) || (axis!=1 && candidate>=current)) support[axis]=following;
            else break;
        }
        const auto span=project(support[0],dx,dy,0)-project(support[1],dx,dy,1);
        const auto thickness=project(support[2],dx,dy,2)-(dx*ay-dy*ax);
        const auto numerator=span*thickness, denominator=dx*dx+dy*dy;
        if (i==0 || numerator*best_den<best_num*denominator) { best_num=numerator; best_den=denominator; }
    }
    const auto divisor=std::gcd(best_num,best_den);
    const std::array<std::int64_t,2> words{best_num/divisor,best_den/divisor};
    if (!output || capacity<16) return -2;
    for (std::size_t i=0; i<2; ++i) for (std::size_t b=0; b<8; ++b)
        output[8*i+b]=static_cast<std::uint8_t>(static_cast<std::uint64_t>(words[i])>>(8*b));
    return 16;
}
