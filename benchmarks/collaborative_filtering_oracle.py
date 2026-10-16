"""Bounded references for Pearson similarity and collaborative rating prediction."""

from __future__ import annotations

import math

MAX_PROFILE_ITEMS = 32
MAX_ITEM_ID = 127
RATING_SCALE = 1_000
MAX_RATING_MILLI = 1_000_000_000
MAX_PEARSON_INPUT_LENGTH = 2 + 4 * MAX_PROFILE_ITEMS
PEARSON_INVALID_RESULT = -2.0

MAX_NEIGHBORS = 64
MAX_USERS = MAX_NEIGHBORS + 1
SIMILARITY_SCALE = 1_000_000_000_000
MAX_PREDICTION_INPUT_LENGTH = 1 + 4 * MAX_USERS
PREDICTION_INVALID_RESULT = -1.0e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _is_packed_i64(values: tuple[int, ...] | list[int], maximum: int) -> bool:
    return (isinstance(values, (tuple, list)) and len(values) <= maximum
            and all(type(value) is int and I64_MIN <= value <= I64_MAX for value in values))


def expected_pearson_similarity(values: tuple[int, ...] | list[int]) -> float:
    """Pearson correlation over common item IDs, preserving first-profile order."""
    if not _is_packed_i64(values, MAX_PEARSON_INPUT_LENGTH) or len(values) < 2:
        return PEARSON_INVALID_RESULT
    first_count = values[0]
    if not 0 <= first_count <= MAX_PROFILE_ITEMS:
        return PEARSON_INVALID_RESULT
    second_count_position = 1 + 2 * first_count
    if second_count_position >= len(values):
        return PEARSON_INVALID_RESULT
    second_count = values[second_count_position]
    if not 0 <= second_count <= MAX_PROFILE_ITEMS or len(values) != second_count_position + 1 + 2 * second_count:
        return PEARSON_INVALID_RESULT

    def read_profile(start: int, count: int) -> dict[int, float] | None:
        profile: dict[int, float] = {}
        for offset in range(start, start + 2 * count, 2):
            item_id, rating_milli = values[offset:offset + 2]
            if (not 0 <= item_id <= MAX_ITEM_ID
                    or item_id in profile
                    or not -MAX_RATING_MILLI <= rating_milli <= MAX_RATING_MILLI):
                return None
            profile[item_id] = rating_milli / RATING_SCALE
        return profile

    first = read_profile(1, first_count)
    second = read_profile(second_count_position + 1, second_count)
    if first is None or second is None:
        return PEARSON_INVALID_RESULT
    common = [(first[item_id], second[item_id]) for item_id in first if item_id in second]
    if not common:
        return 0.0

    average_first = sum(left for left, _ in common) / len(common)
    average_second = sum(right for _, right in common) / len(common)
    numerator = 0.0
    sum_square_first = 0.0
    sum_square_second = 0.0
    for left, right in common:
        difference_first = left - average_first
        difference_second = right - average_second
        numerator += difference_first * difference_second
        sum_square_first += difference_first * difference_first
        sum_square_second += difference_second * difference_second
    denominator = math.sqrt(sum_square_first * sum_square_second)
    return 0.0 if abs(denominator) < 1.0e-10 else numerator / denominator


def expected_prediction(values: tuple[int, ...] | list[int]) -> float:
    """Weighted target-item prediction with injected similarities as inputs."""
    if not _is_packed_i64(values, MAX_PREDICTION_INPUT_LENGTH) or len(values) < 1:
        return PREDICTION_INVALID_RESULT
    user_count = values[0]
    if not 1 <= user_count <= MAX_USERS or len(values) != 1 + 4 * user_count:
        return PREDICTION_INVALID_RESULT

    total_similarity = 0.0
    weighted_sum = 0.0
    target_user_count = 0
    for offset in range(1, len(values), 4):
        is_target_user, has_target_rating, similarity_scaled, rating_milli = values[offset:offset + 4]
        if (is_target_user not in (0, 1) or has_target_rating not in (0, 1)
                or not -SIMILARITY_SCALE <= similarity_scaled <= SIMILARITY_SCALE
                or not -MAX_RATING_MILLI <= rating_milli <= MAX_RATING_MILLI):
            return PREDICTION_INVALID_RESULT
        if is_target_user == 1:
            target_user_count += 1
            continue
        if has_target_rating == 0:
            continue
        similarity = similarity_scaled / SIMILARITY_SCALE
        rating = rating_milli / RATING_SCALE
        total_similarity += abs(similarity)
        weighted_sum += similarity * rating
    if target_user_count != 1:
        return PREDICTION_INVALID_RESULT
    return (0.0 if abs(total_similarity) < 1.0e-10
            else weighted_sum / total_similarity)
