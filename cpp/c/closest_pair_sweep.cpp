#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <set>
#include <utility>
#include <vector>

extern "C" std::int64_t closest_pair_sweep(const std::int64_t* input, std::size_t length) {
    if (!input || length<5 || length>130) return -1;
    const auto raw_n=input[0];
    if (raw_n<2 || raw_n>64) return -1;
    const auto n=static_cast<std::size_t>(raw_n);
    if (length!=1+2*n) return -1;
    std::vector<std::pair<std::int64_t,std::int64_t>> points;
    points.reserve(n);
    for (std::size_t i=0; i<n; ++i) {
        const auto x=input[1+2*i], y=input[2+2*i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000) return -1;
        points.emplace_back(x,y);
    }
    std::sort(points.begin(),points.end());
    for (std::size_t i=1; i<n; ++i) if (points[i]==points[i-1]) return 0;
    std::set<std::pair<std::int64_t,std::int64_t>> active;
    std::size_t left=0;
    std::int64_t best=8000001;
    for (const auto& [x,y]: points) {
        while (left<n && points[left].first<x && (x-points[left].first)*(x-points[left].first)>best) {
            active.erase({points[left].second,points[left].first}); ++left;
        }
        std::int64_t lo=0, hi=3000;
        while (lo<hi) {
            const auto middle=(lo+hi+1)/2;
            if (middle*middle<=best) lo=middle; else hi=middle-1;
        }
        const auto radius=lo;
        for (auto it=active.lower_bound({y-radius,-1001}); it!=active.end() && it->first<=y+radius; ++it) {
            const auto dx=x-it->second, dy=y-it->first;
            best=std::min(best,dx*dx+dy*dy);
        }
        active.emplace(y,x);
    }
    return best;
}
