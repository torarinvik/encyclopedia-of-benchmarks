#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 32;
constexpr std::size_t MAX_DOCS = 8;
constexpr std::size_t MAX_QUERIES = 16;
constexpr std::size_t MAX_INPUT = 68;
constexpr std::size_t MAX_OUTPUT = 144;
constexpr std::size_t LEVELS = 6;

using Previous = std::array<std::int64_t, MAX_N>;
using DocumentArray = std::array<std::int64_t, MAX_N>;
using SparseTable = std::array<std::array<int, MAX_N>, LEVELS>;

std::size_t range_min(std::size_t lo, std::size_t hi, const Previous& previous,
                      const SparseTable& table, const std::array<int, MAX_N + 1>& logs)
{
    const std::size_t length = hi - lo + 1;
    const std::size_t level = static_cast<std::size_t>(logs[length]);
    const std::size_t width = std::size_t{1} << level;
    const int left = table[level][lo];
    const int right = table[level][hi - width + 1];
    if (previous[static_cast<std::size_t>(left)] < previous[static_cast<std::size_t>(right)] ||
        (previous[static_cast<std::size_t>(left)] == previous[static_cast<std::size_t>(right)] && left < right))
        return static_cast<std::size_t>(left);
    return static_cast<std::size_t>(right);
}

void report(std::size_t lo, std::size_t hi, std::size_t query_lo,
            const Previous& previous, const DocumentArray& da, const SparseTable& table,
            const std::array<int, MAX_N + 1>& logs,
            std::array<std::size_t, MAX_DOCS>& ranks,
            std::array<std::uint8_t, MAX_DOCS>& found_docs, std::size_t& count)
{
    if (lo > hi) return;
    const std::size_t index = range_min(lo, hi, previous, table, logs);
    if (previous[index] >= static_cast<std::int64_t>(query_lo)) return;
    ranks[count] = index;
    found_docs[count] = static_cast<std::uint8_t>(da[index]);
    ++count;
    if (index > lo) report(lo, index - 1, query_lo, previous, da, table, logs, ranks, found_docs, count);
    if (index < hi) report(index + 1, hi, query_lo, previous, da, table, logs, ranks, found_docs, count);
}
}

extern "C" std::int64_t muthukrishnan_document_listing(
    const std::int64_t* values, std::size_t length, std::uint8_t* output,
    std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 3 || length > MAX_INPUT) return -1;
    const std::int64_t n_value = values[0], docs_value = values[1], q_value = values[2];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MAX_N) ||
        docs_value < 1 || docs_value > static_cast<std::int64_t>(MAX_DOCS) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(MAX_QUERIES)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    const std::size_t queries = static_cast<std::size_t>(q_value);
    if (length != 3 + n + 2 * queries) return -1;

    DocumentArray da{};
    Previous previous{};
    std::array<std::int64_t, MAX_DOCS> last{};
    last.fill(-1);
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t document = values[3 + i];
        if (document < 0 || document >= docs_value) return -1;
        da[i] = document;
        previous[i] = last[static_cast<std::size_t>(document)];
        last[static_cast<std::size_t>(document)] = static_cast<std::int64_t>(i);
    }
    for (std::size_t query = 0; query < queries; ++query) {
        const std::int64_t lo = values[3 + n + 2 * query];
        const std::int64_t hi = values[4 + n + 2 * query];
        if (lo < 0 || hi < lo || hi >= n_value) return -1;
    }

    std::array<int, MAX_N + 1> logs{};
    for (std::size_t size = 2; size <= n; ++size) logs[size] = logs[size / 2] + 1;
    SparseTable table{};
    for (std::size_t i = 0; i < n; ++i) table[0][i] = static_cast<int>(i);
    const std::size_t level_count = static_cast<std::size_t>(logs[n] + 1);
    for (std::size_t level = 1; level < level_count; ++level) {
        const std::size_t width = std::size_t{1} << level;
        const std::size_t half = width >> 1;
        for (std::size_t start = 0; start + width <= n; ++start) {
            const int left = table[level - 1][start];
            const int right = table[level - 1][start + half];
            table[level][start] = previous[static_cast<std::size_t>(left)] < previous[static_cast<std::size_t>(right)] ||
                (previous[static_cast<std::size_t>(left)] == previous[static_cast<std::size_t>(right)] && left < right)
                ? left : right;
        }
    }

    std::array<std::uint8_t, MAX_OUTPUT> staged{};
    std::size_t written = 0;
    for (std::size_t query = 0; query < queries; ++query) {
        const std::size_t lo = static_cast<std::size_t>(values[3 + n + 2 * query]);
        const std::size_t hi = static_cast<std::size_t>(values[4 + n + 2 * query]);
        const std::size_t count_at = written++;
        std::array<std::size_t, MAX_DOCS> ranks{};
        std::array<std::uint8_t, MAX_DOCS> found_docs{};
        std::size_t count = 0;
        report(lo, hi, lo, previous, da, table, logs, ranks, found_docs, count);
        for (std::size_t i = 1; i < count; ++i) {
            const std::size_t rank = ranks[i];
            const std::uint8_t document = found_docs[i];
            std::size_t j = i;
            while (j > 0 && ranks[j - 1] > rank) {
                ranks[j] = ranks[j - 1];
                found_docs[j] = found_docs[j - 1];
                --j;
            }
            ranks[j] = rank;
            found_docs[j] = document;
        }
        staged[count_at] = static_cast<std::uint8_t>(count);
        for (std::size_t i = 0; i < count; ++i) staged[written++] = found_docs[i];
    }
    if (written > MAX_OUTPUT) return -1;
    if (output == nullptr || output_capacity < written) return -2;
    for (std::size_t i = 0; i < written; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(written);
}
