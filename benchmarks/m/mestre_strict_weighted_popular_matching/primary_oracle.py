"""Category-label pruning for strict weighted popular matching."""

from __future__ import annotations

from collections.abc import Sequence

MAX_APPLICANTS = 4
MAX_JOBS = 5
MAX_WEIGHT = 1000
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_APPLICANTS + MAX_APPLICANTS * MAX_JOBS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
INF = 1 << 60


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], int, list[list[int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    applicants, jobs = values[:2]
    if not 1 <= applicants <= MAX_APPLICANTS or not 1 <= jobs <= MAX_JOBS:
        return None
    if len(values) < 2 + 2 * applicants:
        return None
    weights = list(values[2:2 + applicants])
    lengths = list(values[2 + applicants:2 + 2 * applicants])
    if any(not 1 <= w <= MAX_WEIGHT for w in weights):
        return None
    if any(not 1 <= size <= jobs for size in lengths):
        return None
    if len(values) != 2 + 2 * applicants + sum(lengths):
        return None
    rows: list[list[int]] = []
    cursor = 2 + 2 * applicants
    for size in lengths:
        row = list(values[cursor:cursor + size])
        cursor += size
        if any(not 0 <= job < jobs for job in row) or len(set(row)) != size:
            return None
        rows.append(row)
    return weights, jobs, rows


def _popular_exists(weights: list[int], jobs: int, preferences: list[list[int]]) -> bool:
    applicants = len(weights)
    # Private last-resort jobs make every compared assignment applicant-complete.
    rows = [row + [jobs + a] for a, row in enumerate(preferences)]
    categories = sorted(set(weights), reverse=True)
    category_of_weight = {weight: i for i, weight in enumerate(categories)}
    f = [-1] * applicants
    f_category = [-1] * (jobs + applicants)
    higher_jobs: set[int] = set()

    for category, weight in enumerate(categories):
        members = [a for a in range(applicants) if weights[a] == weight]
        for a in members:
            f[a] = next(job for job in rows[a] if job not in higher_jobs)
        for a in members:
            f_category[f[a]] = category
        higher_jobs.update(f[a] for a in members)

    seconds = [-1] * applicants
    for a in range(applicants):
        category = category_of_weight[weights[a]]
        seconds[a] = next(
            (job for job in rows[a]
             if f_category[job] < 0 or f_category[job] > category), -1)

    label = [INF] * (jobs + applicants)
    keep_f = [True] * applicants
    keep_s = [True] * applicants

    def lambda_min(applicant: int, target: int) -> int:
        best = INF
        for job in rows[applicant]:
            if job == target:
                break
            if f_category[job] >= 0:
                best = min(best, label[job])
        return best

    for category, weight in enumerate(categories):
        if category == 0:
            for a in range(applicants):
                if weights[a] == weight:
                    label[f[a]] = weight
            continue

        members = [a for a in range(applicants) if weights[a] == weight]
        for a in members:
            if lambda_min(a, f[a]) < weight:
                return False

        category_jobs = sorted({f[a] for a in members})
        for job in category_jobs:
            group = [a for a in members if f[a] == job]
            if len(group) == 1:
                a = group[0]
                earlier = lambda_min(a, f[a])
                label[job] = min(weight, earlier - weight)
            else:
                label[job] = weight
                for a in group:
                    if lambda_min(a, job) < 2 * weight:
                        keep_f[a] = False

        for a in members:
            if seconds[a] >= 0 and lambda_min(a, seconds[a]) < weight:
                keep_s[a] = False

    # Mestre's completion test starts from the reduced f/s graph. A second
    # edge that lands on any f-job is removed so the two job classes separate.
    f_jobs = {f[a] for a in range(applicants)}
    for job in f_jobs:
        if not any(f[a] == job and keep_f[a] for a in range(applicants)):
            return False
    edges: list[list[int]] = []
    for a in range(applicants):
        choices = [f[a]] if keep_f[a] else []
        if keep_s[a] and seconds[a] >= 0 and seconds[a] not in f_jobs:
            choices.append(seconds[a])
        edges.append(choices)

    owner = [-1] * (jobs + applicants)

    def augment(applicant: int, seen: list[bool]) -> bool:
        for job in edges[applicant]:
            if seen[job]:
                continue
            seen[job] = True
            previous = owner[job]
            if previous < 0 or augment(previous, seen):
                owner[job] = applicant
                return True
        return False

    for a in range(applicants):
        if not augment(a, [False] * (jobs + applicants)):
            return False
    return True


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    weights, jobs, preferences = parsed
    return int(_popular_exists(weights, jobs, preferences))
