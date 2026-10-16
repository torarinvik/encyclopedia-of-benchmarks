/* Exact golden-triple fraction enumeration for Project Euler 180. */
#include <array>
#include <cstdint>
#include <vector>

namespace {
constexpr std::int64_t max_order = 35;
constexpr std::size_t hash_capacity = std::size_t{1} << 19;
constexpr std::size_t hash_mask = hash_capacity - 1;
constexpr std::int64_t big_base = 10000;
constexpr std::size_t big_limbs = 8;

std::int64_t gcd_i64(std::int64_t a, std::int64_t b) noexcept { while (b) { auto r = a % b; a = b; b = r; } return a; }
std::int64_t integer_sqrt(std::int64_t value) noexcept {
    if (value <= 0) return 0;
    auto root = value, next = (root + value / root) / 2;
    while (next < root) { root = next; next = (root + value / root) / 2; }
    return root;
}
bool insert_fraction(std::vector<std::int64_t>& nums, std::vector<std::int64_t>& dens,
                     std::int64_t num, std::int64_t den) noexcept {
    auto index = static_cast<std::size_t>(((num % hash_capacity) * 1009 + den % hash_capacity) & hash_mask);
    while (dens[index]) {
        if (nums[index] == num && dens[index] == den) return false;
        index = (index + 1) & hash_mask;
    }
    nums[index] = num; dens[index] = den; return true;
}
void record_sum(std::vector<std::int64_t>& nums, std::vector<std::int64_t>& dens,
                std::int64_t xn, std::int64_t xd, std::int64_t yn, std::int64_t yd,
                std::int64_t zn, std::int64_t zd, std::int64_t order) {
    if (zn <= 0 || zd <= 0) return;
    auto g = gcd_i64(zn, zd); zn /= g; zd /= g;
    if (zn >= zd || zd > order) return;
    auto num = xn * yd * zd + yn * xd * zd + zn * xd * yd;
    auto den = xd * yd * zd; g = gcd_i64(num, den);
    insert_fraction(nums, dens, num / g, den / g);
}
void add_big(std::array<std::int64_t, big_limbs>& limbs, std::int64_t value) {
    std::size_t index = 0;
    while (value > 0) { auto total = limbs[index] + value; limbs[index] = total % big_base; value = total / big_base; ++index; }
}
}

extern "C" std::int64_t problem180(std::int64_t order) {
    if (order < 1 || order > max_order) return -1;
    std::vector<std::int64_t> nums(hash_capacity), dens(hash_capacity);
    for (std::int64_t xn = 1; xn <= order; ++xn) for (std::int64_t xd = xn + 1; xd <= order; ++xd) {
        if (gcd_i64(xn, xd) != 1) continue;
        for (std::int64_t yn = 1; yn <= order; ++yn) for (std::int64_t yd = yn + 1; yd <= order; ++yd) {
            if (gcd_i64(yn, yd) != 1 || xn * yd > yn * xd) continue;
            auto zn = xn * yd + xd * yn, zd = xd * yd;
            record_sum(nums, dens, xn, xd, yn, yd, zn, zd, order);
            auto square_num = xn*xn*yd*yd + xd*xd*yn*yn;
            auto square_den = xd*xd*yd*yd;
            auto root_num = integer_sqrt(square_num), root_den = integer_sqrt(square_den);
            if (root_num*root_num == square_num && root_den*root_den == square_den)
                record_sum(nums, dens, xn, xd, yn, yd, root_num, root_den, order);
            zn = xn * yn; zd = xd * yn + xn * yd;
            record_sum(nums, dens, xn, xd, yn, yd, zn, zd, order);
            square_num = xn*xn*yn*yn;
            square_den = xd*xd*yn*yn + xn*xn*yd*yd;
            root_num = integer_sqrt(square_num); root_den = integer_sqrt(square_den);
            if (root_num*root_num == square_num && root_den*root_den == square_den)
                record_sum(nums, dens, xn, xd, yn, yd, root_num, root_den, order);
        }
    }
    std::int64_t common = 1;
    for (std::int64_t factor = 2; factor <= order; ++factor) common = common / gcd_i64(common, factor) * factor;
    std::array<std::int64_t, big_limbs> total{};
    for (std::size_t i = 0; i < hash_capacity; ++i) if (dens[i]) {
        if (common % dens[i] != 0) return -1;
        add_big(total, nums[i] * (common / dens[i]));
    }
    std::int64_t rem = 0;
    for (int i = int(big_limbs) - 1; i >= 0; --i) rem = (rem * big_base + total[std::size_t(i)]) % common;
    auto divisor = gcd_i64(rem, common); rem = 0;
    for (int i = int(big_limbs) - 1; i >= 0; --i) { auto cur = rem * big_base + total[std::size_t(i)]; total[std::size_t(i)] = cur / divisor; rem = cur % divisor; }
    std::int64_t numerator = 0;
    for (int i = int(big_limbs) - 1; i >= 0; --i) { auto limb = total[std::size_t(i)]; if (numerator > (INT64_MAX - limb) / big_base) return -1; numerator = numerator * big_base + limb; }
    auto denominator = common / divisor;
    return numerator > INT64_MAX - denominator ? -1 : numerator + denominator;
}
