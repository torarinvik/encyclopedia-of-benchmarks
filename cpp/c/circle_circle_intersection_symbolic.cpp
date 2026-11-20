// Independently authored draft; not compiled or run.
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t circle_circle_intersection_symbolic(const std::int64_t* v,
        std::size_t n, std::uint8_t* out, std::size_t cap) {
    if (!v || n != 6) return -1;
    for (std::size_t i=0;i<6;++i) if (v[i] < -1000 || v[i] > 1000) return -1;
    if (v[2]<1 || v[5]<1) return -1;
    const auto dx=v[3]-v[0], dy=v[4]-v[1], d=dx*dx+dy*dy;
    std::int64_t words[7]={}; std::size_t count=1;
    if (d==0) words[0]=v[2]==v[5] ? 3 : 0;
    else {
        const auto t=d+v[2]*v[2]-v[5]*v[5], h=4*v[2]*v[2]*d-t*t;
        if (h>=0) {
            const auto den=2*d; count=7;
            words[0]=h==0 ? 1 : 2; words[1]=den*v[0]+dx*t; words[2]=den*v[1]+dy*t;
            words[3]=den; words[4]=-dy; words[5]=dx; words[6]=h;
        }
    }
    const auto needed=8*count;
    if (!out || cap<needed) return -2;
    for (std::size_t i=0;i<count;++i) {
        const auto bits=static_cast<std::uint64_t>(words[i]);
        for (std::size_t j=0;j<8;++j) out[8*i+j]=static_cast<std::uint8_t>(bits>>(8*j));
    }
    return static_cast<std::int64_t>(needed);
}
