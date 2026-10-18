#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t INVALID_RESULT = -1;
constexpr std::size_t MAX_PACKED_LENGTH = 16;

std::int64_t distance_i64(std::int64_t a, std::int64_t b) noexcept
{
    return a >= b ? a - b : b - a;
}
}

extern "C" std::int64_t k_medoids(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 3 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const auto point_count = packed[0], medoid_count = packed[1], max_iter = packed[2];
    if (point_count < 2 || point_count > 8 || medoid_count < 1 || medoid_count > 4 || medoid_count > point_count ||
        max_iter < 1 || max_iter > 16 || length != static_cast<std::size_t>(3 + medoid_count + point_count)) return INVALID_RESULT;
    const auto n = static_cast<std::size_t>(point_count), k = static_cast<std::size_t>(medoid_count);
    std::int64_t medoids[4]{}, points[8]{}, labels[8]{};
    for (std::size_t slot=0; slot<k; ++slot) {
        medoids[slot]=packed[3+slot];
        if (medoids[slot]<0 || medoids[slot]>=point_count) return INVALID_RESULT;
        for (std::size_t j=0;j<slot;++j) if (medoids[j]==medoids[slot]) return INVALID_RESULT;
    }
    for (std::size_t i=0;i<n;++i) {
        points[i]=packed[3+k+i];
        if (points[i]<-16 || points[i]>16) return INVALID_RESULT;
        for (std::size_t j=0;j<i;++j) if (points[j]==points[i]) return INVALID_RESULT;
    }

    for (std::int64_t iteration=0; iteration<max_iter; ++iteration) {
        for (std::size_t i=0;i<n;++i) {
            std::size_t best_slot=0;
            auto best_distance=distance_i64(points[i],points[static_cast<std::size_t>(medoids[0])]);
            for (std::size_t slot=1;slot<k;++slot) {
                const auto distance=distance_i64(points[i],points[static_cast<std::size_t>(medoids[slot])]);
                if (distance<best_distance) { best_distance=distance; best_slot=slot; }
            }
            labels[i]=static_cast<std::int64_t>(best_slot);
        }
        std::int64_t updated[4]{};
        for (std::size_t slot=0;slot<k;++slot) {
            std::size_t first=n;
            for (std::size_t i=0;i<n;++i) if (labels[i]==static_cast<std::int64_t>(slot)) { first=i; break; }
            if (first==n) return INVALID_RESULT;
            auto best_index=first;
            std::int64_t best_cost=0;
            for (std::size_t i=0;i<n;++i) if (labels[i]==static_cast<std::int64_t>(slot)) best_cost+=distance_i64(points[first],points[i]);
            for (std::size_t candidate=first+1;candidate<n;++candidate) {
                if (labels[candidate]!=static_cast<std::int64_t>(slot)) continue;
                std::int64_t cost=0;
                for (std::size_t i=0;i<n;++i) if (labels[i]==static_cast<std::int64_t>(slot)) cost+=distance_i64(points[candidate],points[i]);
                if (cost<best_cost) { best_cost=cost; best_index=candidate; }
            }
            updated[slot]=static_cast<std::int64_t>(best_index);
        }
        bool changed=false;
        for (std::size_t slot=0;slot<k;++slot) if (updated[slot]!=medoids[slot]) changed=true;
        if (!changed) break;
        for (std::size_t slot=0;slot<k;++slot) medoids[slot]=updated[slot];
    }

    std::int64_t result=0;
    for (std::size_t slot=0;slot<k;++slot) result|=medoids[slot]<<(3*slot);
    for (std::size_t i=0;i<n;++i) result|=labels[i]<<(12+2*i);
    return result;
}
