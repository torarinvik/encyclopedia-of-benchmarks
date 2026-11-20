#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <utility>
#include <vector>

namespace {
constexpr std::size_t max_len = 32, max_blocks = 16, max_input = 68;
constexpr std::int64_t insert = 0, copy = 1;

std::int64_t block_hash(const std::int64_t *data, std::size_t start, std::size_t width) {
    std::int64_t value = 0;
    for (std::size_t i = 0; i < width; ++i) value = value * 257 + data[start + i] + 1;
    return value;
}
int suffix_cmp(const std::vector<std::int64_t>& hashes, std::size_t a, std::size_t b) {
    while (a < hashes.size() && b < hashes.size()) {
        if (hashes[a] != hashes[b]) return hashes[a] < hashes[b] ? -1 : 1;
        ++a; ++b;
    }
    if (a == hashes.size() && b == hashes.size()) return 0;
    return a == hashes.size() ? -1 : 1;
}
int prefix_cmp(const std::vector<std::int64_t>& hashes, std::size_t suffix,
               const std::vector<std::int64_t>& query, std::size_t depth) {
    for (std::size_t i = 0; i < depth; ++i) {
        if (suffix + i >= hashes.size()) return -1;
        if (hashes[suffix + i] != query[i]) return hashes[suffix + i] < query[i] ? -1 : 1;
    }
    return 0;
}
std::pair<std::size_t,std::size_t> interval(const std::vector<std::size_t>& sa,
    const std::vector<std::int64_t>& hashes, const std::vector<std::int64_t>& query, std::size_t depth) {
    std::size_t lo = 0, hi = sa.size();
    while (lo < hi) { auto mid = lo + (hi - lo) / 2; if (prefix_cmp(hashes, sa[mid], query, depth) < 0) lo = mid + 1; else hi = mid; }
    const auto first = lo; hi = sa.size();
    while (lo < hi) { auto mid = lo + (hi - lo) / 2; if (prefix_cmp(hashes, sa[mid], query, depth) <= 0) lo = mid + 1; else hi = mid; }
    return {first, lo};
}
std::size_t best_depth(const std::vector<std::size_t>& sa, const std::vector<std::int64_t>& hashes,
                       const std::vector<std::int64_t>& query) {
    std::size_t lo = 0, hi = std::min(sa.size(), query.size()) + 1;
    while (lo + 1 < hi) { auto mid = lo + (hi - lo) / 2; auto [first,last] = interval(sa, hashes, query, mid); if (first < last) lo = mid; else hi = mid; }
    return lo;
}
struct Match { std::size_t source, target, length; };
Match extend(const std::int64_t *ref, std::size_t m, const std::int64_t *ver, std::size_t n,
             std::size_t source, std::size_t target, std::size_t floor) {
    std::size_t length = 0;
    while (source + length < m && target + length < n && ref[source + length] == ver[target + length]) ++length;
    while (source > 0 && target > floor && ref[source - 1] == ver[target - 1]) { --source; --target; ++length; }
    return {source, target, length};
}
bool better(const Match& a, const Match& b) {
    return a.length > b.length || (a.length == b.length && std::pair{a.target,a.source} < std::pair{b.target,b.source});
}
bool find_at(const std::int64_t *ref, std::size_t m, const std::int64_t *ver, std::size_t n,
    std::size_t p, const std::vector<std::size_t>& sa, const std::vector<std::int64_t>& hashes,
    std::size_t target, std::size_t floor, Match& best) {
    const auto qcount = (n - target) / p;
    if (qcount == 0 || sa.empty()) return false;
    std::vector<std::int64_t> query(qcount);
    for (std::size_t i = 0; i < qcount; ++i) query[i] = block_hash(ver, target + i * p, p);
    const auto depth = best_depth(sa, hashes, query);
    if (depth == 0) return false;
    const auto [first,last] = interval(sa, hashes, query, std::max<std::size_t>(1, depth - 1));
    bool found = false;
    for (auto rank = first; rank < last; ++rank) {
        const auto source = sa[rank] * p;
        if (source + p > m) continue;
        auto candidate = extend(ref,m,ver,n,source,target,floor);
        if (candidate.length < p) continue;
        if (!found || better(candidate,best)) { found = true; best = candidate; }
    }
    return found;
}
void store_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[offset+b] = static_cast<std::uint8_t>(bits >> (8*b));
}
}

extern "C" std::int64_t hsadelta_differential_compression(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const auto mv = input[0], nv = input[1], pv = input[2];
    if (mv < 0 || mv > static_cast<std::int64_t>(max_len) || nv < 0 || nv > static_cast<std::int64_t>(max_len) || pv < 2 || pv > 4) return -1;
    const auto m = static_cast<std::size_t>(mv), n = static_cast<std::size_t>(nv), p = static_cast<std::size_t>(pv);
    if (length != 3 + m + n) return -1;
    const auto *ref = input + 3, *ver = input + 3 + m;
    for (std::size_t i = 0; i < m+n; ++i) if (input[3+i] < 0 || input[3+i] > 255) return -1;

    const auto block_count = m >= p ? (m-p)/p + 1 : 0;
    std::vector<std::int64_t> hashes(block_count);
    std::vector<std::size_t> sa(block_count);
    for (std::size_t i=0;i<block_count;++i) { hashes[i]=block_hash(ref,i*p,p); sa[i]=i; }
    std::sort(sa.begin(),sa.end(),[&](auto a,auto b){ const auto order=suffix_cmp(hashes,a,b); return order < 0 || (order == 0 && a < b); });
    std::vector<std::int64_t> tokens;
    std::size_t cursor=0, consumed=0;
    const auto emit_insert = [&](std::size_t start, std::size_t end, auto& dest) {
        if (end <= start) return;
        dest.push_back(insert); dest.push_back(static_cast<std::int64_t>(end-start));
        for (auto i=start;i<end;++i) dest.push_back(ver[i]);
    };
    while (cursor + p <= n) {
        bool found=false; Match best{};
        const auto scan_end=std::min(cursor+p-1,n-p);
        for (auto target=cursor;target<=scan_end;++target) {
            Match candidate{};
            if (find_at(ref,m,ver,n,p,sa,hashes,target,consumed,candidate) && (!found || better(candidate,best))) { found=true; best=candidate; }
        }
        if (!found) { ++cursor; continue; }
        emit_insert(consumed,best.target,tokens);
        tokens.insert(tokens.end(),{copy,static_cast<std::int64_t>(best.source),static_cast<std::int64_t>(best.length)});
        consumed=best.target+best.length; cursor=consumed;
    }
    emit_insert(consumed,n,tokens);
    const auto required=tokens.size()*8;
    if (required && (output == nullptr || capacity < required)) return -2;
    for (std::size_t i=0;i<tokens.size();++i) store_i64(output,8*i,tokens[i]);
    return static_cast<std::int64_t>(required);
}
