/* Unbounded knapsack: take the current item again or skip to the previous item. */
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_items = 16, max_capacity = 100;
std::int64_t solve(int item, int capacity, const std::int64_t *values, const std::int64_t *weights,
                   std::int64_t memo[max_items][max_capacity + 1]) {
    if (item == 0) return (capacity / static_cast<int>(weights[0])) * values[0];
    if (memo[item][capacity] >= 0) return memo[item][capacity];
    const auto skip = solve(item - 1, capacity, values, weights, memo);
    std::int64_t take = 0;
    if (capacity >= weights[item]) take = values[item] + solve(item, capacity - static_cast<int>(weights[item]), values, weights, memo);
    return memo[item][capacity] = std::max(take, skip);
}
}

extern "C" std::int64_t unbounded_knapsack(const std::int64_t *input, std::size_t length) noexcept {
    if (!input || length < 2) return -1;
    const auto nv=input[0], cv=input[1];
    if(nv<0||nv>max_items||cv<0||cv>max_capacity)return -1;
    const auto n=static_cast<std::size_t>(nv);
    if(length!=2+2*n)return -1;
    if(n==0)return 0;
    const auto *values=input+2,*weights=input+2+n;
    for(std::size_t i=0;i<n;++i)if(values[i]<1||values[i]>100||weights[i]<1||weights[i]>100)return -1;
    std::int64_t memo[max_items][max_capacity+1];
    for(auto &row:memo)for(auto &cell:row)cell=-1;
    return solve(static_cast<int>(n)-1,static_cast<int>(cv),values,weights,memo);
}
