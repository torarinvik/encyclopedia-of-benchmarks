#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t offline_range_distinct_fenwick(const std::int64_t* input, std::size_t length) {
    if (!input || length < 3 || length > 195) return -1;
    const auto nr = input[0], qr = input[1];
    if (nr < 1 || nr > 64 || qr < 0 || qr > 64) return -1;
    const auto n = static_cast<std::size_t>(nr), q = static_cast<std::size_t>(qr);
    if (length != 2+n+2*q) return -1;
    for (std::size_t i=0; i<n; ++i) if (input[2+i]<0 || input[2+i]>255) return -1;
    std::array<int,65> tree{}, head; head.fill(-1);
    std::array<int,64> next{};
    std::array<int,256> last; last.fill(-1);
    for (std::size_t i=0; i<q; ++i) {
        const auto left=input[2+n+2*i], right=input[3+n+2*i];
        if (left<0 || left>right || right>nr) return -1;
        next[i]=head[static_cast<std::size_t>(right)]; head[static_cast<std::size_t>(right)]=static_cast<int>(i);
    }
    auto add = [&](std::size_t position, int delta) {
        for (std::size_t i=position+1; i<=n; i+=i & (~i+1)) tree[i]+=delta;
    };
    auto prefix = [&](std::size_t end) {
        int sum=0; for (auto i=end; i; i&=i-1) sum+=tree[i]; return sum;
    };
    std::int64_t result=0;
    for (std::size_t right=0; right<=n; ++right) {
        if (right) {
            auto value=static_cast<std::size_t>(input[1+right]);
            if (last[value]>=0) add(static_cast<std::size_t>(last[value]),-1);
            add(right-1,1); last[value]=static_cast<int>(right-1);
        }
        for (int i=head[right]; i>=0; i=next[static_cast<std::size_t>(i)]) {
            auto left=static_cast<std::size_t>(input[2+n+2*static_cast<std::size_t>(i)]);
            result+=static_cast<std::int64_t>(i+1)*(prefix(right)-prefix(left));
        }
    }
    return result;
}
