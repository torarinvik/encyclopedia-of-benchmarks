// Clean-room bounded Kierstead-Trotter online interval coloring profile.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxIntervals = 64;
constexpr std::size_t kMaxInput = 129;
void store_i64_le(std::uint8_t* out, std::size_t offset, std::int64_t value) {
  std::uint64_t bits = static_cast<std::uint64_t>(value);
  for (std::size_t byte = 0; byte < 8; ++byte) {
    out[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
    bits >>= 8;
  }
}
bool level_fits(const std::int64_t* left, const std::int64_t* right,
                const std::size_t* levels, std::size_t last,
                std::size_t candidate_level) {
  for (std::size_t anchor = 0; anchor <= last; ++anchor) {
    const auto point = left[anchor];
    std::size_t overlap = 0;
    for (std::size_t item = 0; item <= last; ++item) {
      if ((item == last || levels[item] <= candidate_level) &&
          left[item] <= point && point <= right[item]) ++overlap;
    }
    if (overlap > candidate_level) return false;
  }
  return true;
}
}  // namespace

extern "C" std::int64_t online_interval_coloring(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
  if (input == nullptr || length < 1 || length > kMaxInput || input[0] < 0 ||
      input[0] > static_cast<std::int64_t>(kMaxIntervals) ||
      length != 1 + 2 * static_cast<std::size_t>(input[0])) return -1;
  const auto n = static_cast<std::size_t>(input[0]);
  std::int64_t left[kMaxIntervals], right[kMaxIntervals];
  std::size_t levels[kMaxIntervals], local[kMaxIntervals], colors[kMaxIntervals];
  for (std::size_t i = 0; i < n; ++i) {
    left[i] = input[1 + 2 * i]; right[i] = input[2 + 2 * i];
    if (left[i] < -1000 || left[i] > 1000 || right[i] < -1000 ||
        right[i] > 1000 || left[i] > right[i]) return -1;
  }
  const auto output_bytes = 8 * n;
  if (output == nullptr || capacity < output_bytes) return -2;
  for (std::size_t i = 0; i < n; ++i) {
    std::size_t level = 1;
    while (!level_fits(left, right, levels, i, level)) {
      if (++level > i + 1) return -1;
    }
    levels[i] = level;
    bool used[3] = {false, false, false};
    for (std::size_t j = 0; j < i; ++j)
      if (levels[j] == level && left[j] <= right[i] && left[i] <= right[j] && local[j] < 3)
        used[local[j]] = true;
    std::size_t color = 0;
    while (color < 3 && used[color]) ++color;
    if (color == 3) return -1;
    local[i] = color;
    colors[i] = 3 * (level - 1) + color;
  }
  for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, static_cast<std::int64_t>(colors[i]));
  return static_cast<std::int64_t>(output_bytes);
}
