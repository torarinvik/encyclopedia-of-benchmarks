#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kScale=1'000'000;
constexpr std::int64_t kMinProbabilityMicro=1;
constexpr std::int64_t kMaxProbabilityMicro=999'999;
constexpr std::int64_t kMinRatioMicro=1'000;
constexpr std::int64_t kMaxRatioMicro=100'000'000;
constexpr std::size_t kMaxInputLength=3;
constexpr double kInvalidResult=-1.0e300;
}

extern "C" double kelly_criterion(const std::int64_t *values,std::size_t length) noexcept {
    if(values==nullptr||length!=2||length>kMaxInputLength)return kInvalidResult;
    const auto probability_micro=values[0],ratio_micro=values[1];
    if(probability_micro<kMinProbabilityMicro||probability_micro>kMaxProbabilityMicro
            ||ratio_micro<kMinRatioMicro||ratio_micro>kMaxRatioMicro)return kInvalidResult;
    const double win_probability=static_cast<double>(probability_micro)/static_cast<double>(kScale);
    const double win_loss_ratio=static_cast<double>(ratio_micro)/static_cast<double>(kScale);
    const double loss_probability=1.0-win_probability;
    return (win_probability*win_loss_ratio-loss_probability)/win_loss_ratio;
}
