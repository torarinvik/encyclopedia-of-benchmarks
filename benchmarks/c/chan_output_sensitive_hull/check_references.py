"""Unexecuted source-level checks for the in-progress Chan references."""

from itertools import combinations, permutations
import json
import struct
from pathlib import Path

from .grouped_reference import expected_output as grouped
from .independent_oracle import expected_output as independent
from .tangent_oracle import wrapping_candidate
from .tangent_search_draft import wrapping_candidate as tangent_search


def reference_issues():
    issues = []
    workload = json.loads((Path(__file__).parent / "workload.json").read_text(encoding="utf-8"))
    for case in workload["cases"]:
        arguments = (case["input_values"], case["output_capacity"],
                     case.get("output_is_null", False), case.get("input_is_null", False),
                     case["input_length"])
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        if grouped(*arguments) != expected or independent(*arguments) != expected:
            issues.append(f"fixture disagreement: {case['id']}")
    # A five-vertex parabola forces the initial four-step attempt to retry.
    retry_points = tuple((x, x*x) for x in range(-2, 3))
    # Different input orders change groups and include singleton subhulls.
    for points in permutations(retry_points):
        values = (len(points), *(coordinate for point in points for coordinate in point))
        if grouped(values) != independent(values):
            issues.append("five-vertex retry or grouping disagreement")
            break
    mixed_points = ((0, 0), (10, 0), (0, 10), (2, 3), (3, 2))
    for points in permutations(mixed_points):
        values = (len(points), *(coordinate for point in points for coordinate in point))
        expected = independent(values)
        if expected[0] != 48 or grouped(values) != expected:
            issues.append("interior-point grouping disagreement")
            break
    vertical_pairs = ((0, 0), (0, 4), (3, 1), (3, 5))
    for points in permutations(vertical_pairs):
        values = (len(points), *(coordinate for point in points for coordinate in point))
        expected = independent(values)
        if expected[0] != 64 or grouped(values) != expected:
            issues.append("equal-x ordering or grouping disagreement")
            break
    maximum_points = tuple((x, x*x) for x in range(-16, 16))
    for points in (maximum_points, tuple(reversed(maximum_points))):
        values = (len(points), *(coordinate for point in points for coordinate in point))
        expected = independent(values)
        if expected[0] != 512 or grouped(values) != expected:
            issues.append("maximum-size convex hull disagreement")
        if grouped(values, 511) != (-2, b"") or independent(values, 511) != (-2, b""):
            issues.append("maximum-size short-output handling differs")
    malformed = (3, 0, 0, 1, 1, 2, 2)
    if (grouped(malformed, 0, output_is_null=True) != (-1, b"")
            or independent(malformed, 0, output_is_null=True) != (-1, b"")):
        issues.append("invalid input must take precedence over output errors")
    # A query on a group hull must choose its counterclockwise successor.
    for index, point in enumerate(retry_points):
        if wrapping_candidate(retry_points, point) != retry_points[(index + 1) % len(retry_points)]:
            issues.append("on-hull tangent candidate differs from successor")
            break
    if wrapping_candidate(((0, 0),), (0, 0)) is not None:
        issues.append("singleton containing query must have no candidate")
    if wrapping_candidate(((1, 0),), (0, 0)) != (1, 0):
        issues.append("external singleton tangent candidate differs")
    if wrapping_candidate(((0, 0), (3, 0)), (1, -2)) != (3, 0):
        issues.append("two-point external tangent candidate differs")
    if wrapping_candidate(((0, 0), (3, 0)), (0, 0)) != (3, 0):
        issues.append("two-point on-hull tangent candidate differs")
    triangle = ((0, 0), (3, 0), (0, 3))
    # Exercise each side of the polygon and cyclic rotations of its storage.
    tangent_examples = (((-1, 1), (0, 0)), ((4, 1), (0, 3)), ((1, -2), (3, 0)))
    for offset in range(len(triangle)):
        polygon = triangle[offset:] + triangle[:offset]
        for query, expected in tangent_examples:
            if wrapping_candidate(polygon, query) != expected:
                issues.append("external tangent candidate depends on rotation or query side")
                break
            if tangent_search(polygon, query) != expected:
                issues.append("binary tangent draft disagrees with explicit triangle case")
                break
    # Subsets of a strictly convex parabola are also convex; every excluded
    # point is a global extreme vertex and lies outside the subgroup hull.
    for size in range(1, len(retry_points)):
        for subgroup in combinations(retry_points, size):
            for query in retry_points:
                if query in subgroup:
                    continue
                expected = wrapping_candidate(subgroup, query)
                for offset in range(size):
                    rotated = subgroup[offset:] + subgroup[:offset]
                    if tangent_search(rotated, query) != expected:
                        issues.append("binary tangent draft disagrees on a rotated subgroup")
                        return issues
    # The independent reference rejects degenerate sets; compare only valid
    # subsets to avoid treating invalid input as an algorithm failure.
    grid = tuple((x, y) for x in range(-1, 2) for y in range(-1, 2))
    # Check external tangents on all general-position five-point grid sets.
    # A vertex of the full hull is outside the hull of any subgroup that
    # excludes it; the independent hull oracle supplies both cyclic orders.
    for points in combinations(grid, 5):
        values = (len(points), *(coordinate for point in points for coordinate in point))
        result, payload = independent(values)
        if result < 0:
            continue
        words = struct.unpack("<" + "q" * (result // 8), payload)
        full_hull = tuple(zip(words[::2], words[1::2]))
        for query in full_hull:
            others = tuple(point for point in points if point != query)
            for size in (3, 4):
                for subgroup in combinations(others, size):
                    subgroup_values = (size, *(coordinate for point in subgroup for coordinate in point))
                    subgroup_result, subgroup_payload = independent(subgroup_values)
                    subgroup_words = struct.unpack("<" + "q" * (subgroup_result // 8), subgroup_payload)
                    polygon = tuple(zip(subgroup_words[::2], subgroup_words[1::2]))
                    expected = wrapping_candidate(polygon, query)
                    for offset in range(len(polygon)):
                        rotated = polygon[offset:] + polygon[:offset]
                        if tangent_search(rotated, query) != expected:
                            issues.append("binary tangent draft disagrees on a general-position grid subgroup")
                            return issues
    for points in combinations(grid, 4):
        values = (len(points), *(coordinate for point in points for coordinate in point))
        expected = independent(values)
        if expected[0] >= 0 and grouped(values) != expected:
            issues.append("small general-position hull disagreement")
            break
    return issues
