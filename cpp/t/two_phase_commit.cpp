#include <cstddef>
#include <cstdint>

extern "C" std::int64_t two_phase_commit(const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::int64_t MaxParticipants = 64;
    if (input == nullptr || length < 5 || length > 68) return -1;
    const auto participantCount = input[0], timeoutMs = input[1];
    const auto startTimeMs = input[2], currentTimeMs = input[3];
    if (participantCount < 1 || participantCount > MaxParticipants
        || length != 4 + static_cast<std::size_t>(participantCount)
        || timeoutMs < 1 || startTimeMs < 0
        || currentTimeMs < startTimeMs) return -1;

    std::int64_t votesReceived = 0, commitVotes = 0;
    bool hasAbort = false;
    for (std::size_t i = 0; i < static_cast<std::size_t>(participantCount); ++i) {
        const auto vote = input[4 + i];
        if (vote < 0 || vote > 2) return -1;
        if (vote == 0) { ++votesReceived; ++commitVotes; }
        else if (vote == 1) { ++votesReceived; hasAbort = true; }
    }

    std::int64_t state = 1;
    if (votesReceived == participantCount) state = hasAbort ? 3 : 2;
    const std::int64_t timedOut = currentTimeMs - startTimeMs > timeoutMs;
    return (((state * 65 + votesReceived) * 65 + commitVotes) * 2 + timedOut);
}
