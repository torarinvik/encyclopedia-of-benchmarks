"""Independent oracle for the bounded two-phase commit coordinator trace."""

from __future__ import annotations

MAX_PARTICIPANTS = 64
MAX_INPUT_LENGTH = 4 + MAX_PARTICIPANTS


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not values
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if len(values) < 5 or len(values) > MAX_INPUT_LENGTH:
        return -1

    participant_count, timeout_ms, start_time_ms, current_time_ms = values[:4]
    if not 1 <= participant_count <= MAX_PARTICIPANTS:
        return -1
    if timeout_ms < 1:
        return -1
    if start_time_ms < 0 or current_time_ms < start_time_ms:
        return -1
    if len(values) != 4 + participant_count:
        return -1

    votes = values[4:]
    if any(vote not in (0, 1, 2) for vote in votes):
        return -1

    # 0 is commit; 1 is abort; 2 leaves the source's no_response sentinel intact.
    votes_received = sum(vote != 2 for vote in votes)
    commit_votes = sum(vote == 0 for vote in votes)
    state = 1  # preparing
    if votes_received == participant_count:
        state = 3 if any(vote == 1 for vote in votes) else 2
    timed_out = int(current_time_ms - start_time_ms > timeout_ms)
    return (((state * 65 + votes_received) * 65 + commit_votes) * 2 + timed_out)
