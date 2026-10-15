#!/usr/bin/env python3
"""Record a built read-only i64-array scalar benchmark."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import platform
import shlex
import struct
import subprocess
import sys
from functools import lru_cache

from build_abi import ROOT, sha256_file

I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def same_trees_expected(values: list[int]) -> int:
    """Return the indexed-tree equality result for the packed pair input."""
    if len(values) < 4:
        return -1

    def parse_tree(offset: int) -> tuple[dict[str, object] | None, int]:
        if offset + 2 > len(values):
            return None, offset
        count, root = values[offset], values[offset + 1]
        if not 0 <= count <= 1023:
            return None, offset
        end = offset + 2 + 3 * count
        if end > len(values):
            return None, offset
        rows = [values[index:index + 3] for index in range(offset + 2, end, 3)]
        if count == 0:
            return ({"count": 0, "root": root, "rows": rows} if root == -1 else None), end
        if not 0 <= root < count:
            return None, end
        parents = [0] * count
        for value, left, right in rows:
            if not -(2**31) <= value <= 2**31 - 1:
                return None, end
            for child in (left, right):
                if child < -1 or child >= count:
                    return None, end
                if child >= 0:
                    parents[child] += 1
                    if parents[child] > 1:
                        return None, end
        if any(parent != (0 if index == root else 1) for index, parent in enumerate(parents)):
            return None, end
        seen: set[int] = set()
        queue = [root]
        for index in queue:
            if index in seen:
                return None, end
            seen.add(index)
            _, left, right = rows[index]
            if left >= 0:
                queue.append(left)
            if right >= 0:
                queue.append(right)
        if len(seen) != count:
            return None, end
        return {"count": count, "root": root, "rows": rows}, end

    first, offset = parse_tree(0)
    second, offset = parse_tree(offset)
    if first is None or second is None or offset != len(values):
        return -1
    if first["count"] + second["count"] > 1023:
        return -1
    root1, root2 = first["root"], second["root"]
    if root1 == -1 or root2 == -1:
        return int(root1 == root2)
    rows1, rows2 = first["rows"], second["rows"]
    pending = [(root1, root2)]
    for index1, index2 in pending:
        value1, left1, right1 = rows1[index1]
        value2, left2, right2 = rows2[index2]
        if value1 != value2 or (left1 == -1) != (left2 == -1) or (right1 == -1) != (right2 == -1):
            return 0
        if left1 >= 0:
            pending.append((left1, left2))
        if right1 >= 0:
            pending.append((right1, right2))
    return 1


def encode_case(case: dict, algorithm: str) -> list[int]:
    values, expected = case.get("input_values"), case.get("expected_result")
    if (not isinstance(values, list) or len(values) > 100001
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or type(expected) is not int):
        raise ValueError("array scalar cases require up to 100001 signed 64-bit values")
    if algorithm == "rod_cutting":
        valid = (1 <= len(values) - 1 <= 30 and values[0] == len(values) - 1
                 and all(1 <= value <= 1000 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            length, prices = values[0], values[1:]
            profit = [0] * (length + 1)
            for rod_length in range(1, length + 1):
                best = I64_MIN
                for first_cut in range(1, rod_length + 1):
                    best = max(best, prices[first_cut - 1] + profit[rod_length - first_cut])
                profit[rod_length] = best
            expected_from_source = profit[length]
        if expected != expected_from_source:
            raise ValueError("rod_cutting expected_result must match the bounded bottom-up first-cut recurrence")
    elif algorithm == "count_vowels_consonants":
        if len(values) > 100_000 or any(not 0 <= value <= 127 for value in values):
            raise ValueError("count_vowels_consonants requires at most 100000 ASCII code points")
        vowels = consonants = 0
        for codepoint in values:
            if 65 <= codepoint <= 90 or 97 <= codepoint <= 122:
                letter = codepoint | 32
                if letter in (97, 101, 105, 111, 117):
                    vowels += 1
                else:
                    consonants += 1
        expected_from_source = vowels * (2**32) + consonants
        if expected != expected_from_source:
            raise ValueError("count_vowels_consonants expected_result must match the packed ASCII counts")
    elif algorithm == "count_islands_in_matrix":
        valid_shape = (
            len(values) >= 2
            and 1 <= values[0] <= 16
            and 1 <= values[1] <= 16
            and len(values) == 2 + values[0] * values[1]
            and all(value in (0, 1) for value in values[2:])
        )
        if not valid_shape:
            if expected != -1:
                raise ValueError("invalid count_islands_in_matrix inputs must return -1")
        else:
            rows, columns = values[:2]
            cells = values[2:]
            visited: set[int] = set()
            island_count = 0
            for start, cell in enumerate(cells):
                if cell != 1 or start in visited:
                    continue
                island_count += 1
                visited.add(start)
                stack = [start]
                while stack:
                    current = stack.pop()
                    row, column = divmod(current, columns)
                    for next_row in range(max(0, row - 1), min(rows, row + 2)):
                        for next_column in range(max(0, column - 1), min(columns, column + 2)):
                            neighbor = next_row * columns + next_column
                            if cells[neighbor] == 1 and neighbor not in visited:
                                visited.add(neighbor)
                                stack.append(neighbor)
            if expected != island_count:
                raise ValueError("count_islands_in_matrix expected_result must match eight-neighbor connectivity")
    elif algorithm == "number_of_islands":
        valid_shape = (
            len(values) >= 2
            and 1 <= values[0] <= 16
            and 1 <= values[1] <= 16
            and len(values) == 2 + values[0] * values[1]
            and all(value in (0, 1) for value in values[2:])
        )
        if not valid_shape:
            if expected != -1:
                raise ValueError("invalid number_of_islands inputs must return -1")
        else:
            rows, columns = values[:2]
            cells = values[2:]
            visited: set[int] = set()
            island_count = 0
            for start, cell in enumerate(cells):
                if cell != 1 or start in visited:
                    continue
                island_count += 1
                visited.add(start)
                stack = [start]
                while stack:
                    current = stack.pop()
                    row, column = divmod(current, columns)
                    for next_row, next_column in ((row - 1, column), (row + 1, column),
                                                  (row, column - 1), (row, column + 1)):
                        if 0 <= next_row < rows and 0 <= next_column < columns:
                            neighbor = next_row * columns + next_column
                            if cells[neighbor] == 1 and neighbor not in visited:
                                visited.add(neighbor)
                                stack.append(neighbor)
            if expected != island_count:
                raise ValueError("number_of_islands expected_result must match four-neighbor connectivity")
    elif algorithm == "equilibrium_index_in_array":
        valid_shape = (len(values) >= 1 and 0 <= values[0] <= 1024 and len(values) == values[0] + 1
                       and all(-(2**31) <= value <= 2**31 - 1 for value in values[1:]))
        if not valid_shape:
            expected_from_source = -2
        else:
            items = values[1:]
            remaining_sum = sum(items)
            left_sum = 0
            expected_from_source = -1
            for index, value in enumerate(items):
                remaining_sum -= value
                if left_sum == remaining_sum:
                    expected_from_source = index
                    break
                left_sum += value
        if expected != expected_from_source:
            raise ValueError("equilibrium_index_in_array expected_result must be the first index with equal side sums")
    elif algorithm == "check_snake_case":
        if len(values) > 4096 or any(not 32 <= value <= 126 for value in values):
            expected_from_source = -2
        else:
            expected_from_source = int(95 in values)
        if expected != expected_from_source:
            raise ValueError("check_snake_case expected_result must match the printable-ASCII underscore predicate")
    elif algorithm == "check_kebab_case":
        if len(values) > 4096 or any(not 32 <= value <= 126 for value in values):
            expected_from_source = -2
        elif 95 in values:
            expected_from_source = 0
        else:
            def ascii_word(value: int) -> bool:
                return 48 <= value <= 57 or 65 <= value <= 90 or 97 <= value <= 122

            expected_from_source = int(any(
                value == 45 and ascii_word(values[index - 1]) and ascii_word(values[index + 1])
                for index, value in enumerate(values[1:-1], start=1)
            ))
        if expected != expected_from_source:
            raise ValueError("check_kebab_case expected_result must match the printable-ASCII hyphen predicate")
    elif algorithm == "is_lower":
        if len(values) > 4096 or any(not 32 <= value <= 126 for value in values):
            expected_from_source = -1
        else:
            expected_from_source = int(not any(65 <= value <= 90 for value in values))
        if expected != expected_from_source:
            raise ValueError("is_lower expected_result must be 1 exactly when no ASCII uppercase letter occurs")
    elif algorithm == "alphabetical":
        valid = len(values) <= 256 and all(0 <= value <= 127 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            letters = []
            for value in values:
                if 65 <= value <= 90:
                    letters.append(value + 32)
                elif 97 <= value <= 122:
                    letters.append(value)
                else:
                    break
            expected_from_source = int(bool(values) and len(letters) == len(values)
                                       and all(left <= right for left, right in zip(letters, letters[1:])))
        if expected != expected_from_source:
            raise ValueError("alphabetical expected_result must match the ASCII case-insensitive order predicate")
    elif algorithm == "indian_phone_validator":
        import re

        if not 1 <= len(values) <= 18 or any(not 0 <= value <= 127 for value in values):
            expected_from_source = -1
        else:
            text = bytes(values).decode("ascii")
            pattern = r"^(\+91[\-\s]?)?[0]?(91)?[789]\d{9}$"
            expected_from_source = int(re.search(pattern, text) is not None)
        if expected != expected_from_source:
            raise ValueError("indian_phone_validator expected_result must match the bounded source regular expression")
    elif algorithm == "count_nice_subarrays":
        valid = (len(values) >= 2 and 0 <= values[0] <= 4096
                 and 1 <= values[1] <= 4096 and len(values) == values[0] + 2
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[2:]))
        if not valid:
            expected_from_source = -1
        else:
            n, target = values[:2]
            prefix_counts = {0: 1}
            odd_prefix = answer = 0
            for value in values[2:]:
                odd_prefix += value & 1
                answer += prefix_counts.get(odd_prefix - target, 0)
                prefix_counts[odd_prefix] = prefix_counts.get(odd_prefix, 0) + 1
            expected_from_source = answer
        if expected != expected_from_source:
            raise ValueError("count_nice_subarrays expected_result must match the exact odd-count prefix oracle")
    elif algorithm == "count_substrings":
        valid = (len(values) >= 2 and 0 <= values[0] <= 4096 and 0 <= values[1] <= 4096
                 and len(values) == 2 + values[0] + values[1]
                 and all(0 <= value <= 127 for value in values[2:]))
        if not valid:
            expected_from_source = -1
        else:
            text_length, pattern_length = values[:2]
            text = values[2:2 + text_length]
            pattern = values[2 + text_length:]
            if pattern_length == 0:
                expected_from_source = text_length + 1
            else:
                expected_from_source = sum(
                    text[start:start + pattern_length] == pattern
                    for start in range(text_length - pattern_length + 1)
                )
        if expected != expected_from_source:
            raise ValueError("count_substrings expected_result must count overlapping ASCII matches")
    elif algorithm == "count_consonants":
        valid = (1 <= len(values) <= 4096 and all(32 <= value <= 126 for value in values)
                 and values != [48])
        if not valid:
            expected_from_source = -1
        else:
            expected_from_source = sum(
                1 for value in values
                if (65 <= value <= 90 or 97 <= value <= 122)
                and (value | 32) not in (97, 101, 105, 111, 117)
            )
        if expected != expected_from_source:
            raise ValueError("count_consonants expected_result must match the ASCII consonant count")
    elif algorithm == "count_char":
        valid = len(values) <= 4096 and all(0 <= value <= 127 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            java_regex_whitespace = {9, 10, 11, 12, 13, 32}
            expected_from_source = sum(value not in java_regex_whitespace for value in values)
        if expected != expected_from_source:
            raise ValueError("count_char expected_result must count ASCII values outside Java regex whitespace")
    elif algorithm == "parity_outlier":
        valid = (len(values) >= 1 and 3 <= values[0] <= 65 and values[0] % 2 == 1
                 and len(values) == values[0] + 1
                 and all(0 <= value <= 2**31 - 1 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            evens = [value for value in values[1:] if value % 2 == 0]
            odds = [value for value in values[1:] if value % 2 == 1]
            if len(evens) == 1 and len(odds) >= 2:
                expected_from_source = evens[0]
            elif len(odds) == 1 and len(evens) >= 2:
                expected_from_source = odds[0]
            else:
                expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("parity_outlier expected_result must match the unique parity singleton")
    elif algorithm == "is_contains_unique_chars":
        valid = len(values) <= 4096 and all(0 <= value <= 127 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            expected_from_source = int(len(values) == len(set(values)))
        if expected != expected_from_source:
            raise ValueError("is_contains_unique_chars expected_result must match exact ASCII uniqueness")
    elif algorithm == "is_pangram":
        valid = len(values) <= 4096 and all(0 <= value <= 127 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            letters = {value | 32 for value in values if 65 <= value <= 90 or 97 <= value <= 122}
            expected_from_source = int(len(letters) == 26)
        if expected != expected_from_source:
            raise ValueError("is_pangram expected_result must match the case-insensitive ASCII alphabet predicate")
    elif algorithm == "is_uppercase":
        valid = len(values) <= 4096 and all(32 <= value <= 126 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            expected_from_source = int(not any(97 <= value <= 122 for value in values))
        if expected != expected_from_source:
            raise ValueError("is_uppercase expected_result must be 1 exactly when no ASCII lowercase letter occurs")
    elif algorithm == "percentage_of_letters":
        valid = (2 <= len(values) <= 4097 and 0 <= values[0] <= 127
                 and (65 <= values[0] <= 90 or 97 <= values[0] <= 122)
                 and all(0 <= value <= 127 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            target = values[0] | 32
            matches = sum(1 for value in values[1:]
                          if (65 <= value <= 90 or 97 <= value <= 122) and (value | 32) == target)
            expected_from_source = 100 * matches // (len(values) - 1)
        if expected != expected_from_source:
            raise ValueError("percentage_of_letters expected_result must match the floored ASCII percentage")
    elif algorithm == "trapped_rainwater_two_pointer":
        valid = len(values) <= 4096 and all(0 <= value <= 1_000_000 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            left, right = 0, len(values) - 1
            left_maximum = right_maximum = water = 0
            while left < right:
                if values[left] < values[right]:
                    left_maximum = max(left_maximum, values[left])
                    water += left_maximum - values[left]
                    left += 1
                else:
                    right_maximum = max(right_maximum, values[right])
                    water += right_maximum - values[right]
                    right -= 1
            expected_from_source = water
        if expected != expected_from_source:
            raise ValueError("trapped_rainwater_two_pointer expected_result must match the bounded two-pointer sum")
    elif algorithm in {"max", "min"}:
        valid = (len(values) >= 2 and 1 <= values[0] <= 256 and len(values) == values[0] + 1
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[1:]))
        if not valid:
            expected_from_source = I64_MIN
        elif algorithm == "max":
            expected_from_source = max(values[1:])
        else:
            expected_from_source = min(values[1:])
        if expected != expected_from_source:
            raise ValueError(f"{algorithm} expected_result must match the nonempty signed-i32 extrema")
    elif algorithm == "count_sentences":
        valid = (len(values) >= 1 and 0 <= values[0] <= 4096
                 and len(values) == 1 + values[0]
                 and all(0 <= value <= 127 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            text = bytes(values[1:]).strip(b"\x00\t\n\v\r ")
            regex_whitespace = {9, 10, 11, 12, 13, 32}
            word_bytes = set(range(48, 58)) | set(range(65, 91)) | set(range(97, 123)) | {95}
            sentence_count = 0
            index = 0
            while index + 1 < len(text):
                previous, terminator = text[index], text[index + 1]
                eligible_previous = previous not in regex_whitespace | {ord("|"), ord("^"), ord(".")}
                eligible_terminator = terminator in {ord("."), ord("!"), ord("?")}
                next_is_word = index + 2 < len(text) and text[index + 2] in word_bytes
                if eligible_previous and eligible_terminator and not next_is_word:
                    sentence_count += 1
                    index += 2
                else:
                    index += 1
            expected_from_source = sentence_count
        if expected != expected_from_source:
            raise ValueError("count_sentences expected_result must match the trimmed ASCII regex count")
    elif algorithm == "validate_email":
        valid = (len(values) >= 1 and 0 <= values[0] <= 1024
                 and len(values) == 1 + values[0]
                 and all(0 <= value <= 127 for value in values[1:]))
        if not valid or values[0] == 0:
            expected_from_source = -1
        else:
            text = bytes(values[1:])
            whitespace = {9, 10, 11, 12, 13, 32}
            at = text.find(b"@")
            allowed = all(byte not in whitespace for byte in text)
            domain = text[at + 1:] if at >= 0 else b""
            has_domain_dot = any(0 < index < len(domain) - 1 and byte == ord(".")
                                 for index, byte in enumerate(domain))
            expected_from_source = int(allowed and text.count(b"@") == 1
                                       and at > 0 and has_domain_dot)
        if expected != expected_from_source:
            raise ValueError("validate_email expected_result must match the bounded JavaScript regex")
    elif algorithm == "is_sorted":
        valid = len(values) <= 4096 and all(-(2**31) <= value <= 2**31 - 1 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            expected_from_source = int(all(left <= right for left, right in zip(values, values[1:])))
        if expected != expected_from_source:
            raise ValueError("is_sorted expected_result must match the Lua nondecreasing numeric predicate")
    elif algorithm == "is_subsequence":
        valid = (len(values) >= 2 and 0 <= values[0] <= 4096 and 0 <= values[1] <= 4096
                 and len(values) == 2 + values[0] + values[1]
                 and all(0 <= value <= 0x10FFFF and not 0xD800 <= value <= 0xDFFF
                         for value in values[2:]))
        if not valid:
            expected_from_source = -1
        else:
            main_length, sub_length = values[:2]
            main = values[2:2 + main_length]
            sub = values[2 + main_length:]
            sub_index = 0
            for codepoint in main:
                if sub_index < sub_length and codepoint == sub[sub_index]:
                    sub_index += 1
            expected_from_source = int(sub_index == sub_length)
        if expected != expected_from_source:
            raise ValueError("is_subsequence expected_result must match the Unicode-scalar greedy scan")
    elif algorithm == "golomb_sequence_validator":
        valid = (1 <= len(values) <= 1024 and values[0] == len(values)
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            n = values[0]
            sequence = [0] * n
            sequence[0] = 1
            for index in range(1, n):
                prior = sequence[index - 1]
                previous_index = index - sequence[prior]
                sequence[index] = 1 + sequence[previous_index]
            expected_from_source = int(values[1:] == sequence[1:])
        if expected != expected_from_source:
            raise ValueError("golomb_sequence_validator expected_result must match the generated Golomb prefix")
    elif algorithm == "sum_of_two_integers":
        valid = (len(values) == 2
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values))
        expected_from_source = sum(values) if valid else -1
        if expected != expected_from_source:
            raise ValueError("sum_of_two_integers expected_result must match the signed-i32 pair sum")
    elif algorithm == "validate_subsequence":
        valid = (len(values) >= 2 and 0 <= values[0] <= 4096 and 0 <= values[1] <= 4096
                 and len(values) == 2 + values[0] + values[1]
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[2:]))
        if not valid:
            expected_from_source = -1
        else:
            array_length, sequence_length = values[:2]
            array = values[2:2 + array_length]
            sequence = values[2 + array_length:]
            if not array:
                expected_from_source = 0
            else:
                sequence_index = 0
                for value in array:
                    if sequence_index < sequence_length and value == sequence[sequence_index]:
                        sequence_index += 1
                expected_from_source = int(sequence_index == sequence_length)
        if expected != expected_from_source:
            raise ValueError("validate_subsequence expected_result must match the packed greedy scan")
    elif algorithm == "binary_tree_is_sorted_local":
        missing = -(2**31) - 1
        valid = (1 <= len(values) <= 255 and values[0] != missing
                 and all(value == missing or -(2**31) <= value <= 2**31 - 1 for value in values))
        if valid:
            for index in range(1, len(values)):
                if values[index] != missing and values[(index - 1) // 2] == missing:
                    valid = False
                    break
        if not valid:
            expected_from_source = -1
        else:
            ordered = True
            for index, value in enumerate(values):
                if value == missing:
                    continue
                left, right = 2 * index + 1, 2 * index + 2
                if left < len(values) and values[left] != missing and values[left] > value:
                    ordered = False
                    break
                if right < len(values) and values[right] != missing and values[right] < value:
                    ordered = False
                    break
            expected_from_source = int(ordered)
        if expected != expected_from_source:
            raise ValueError("binary_tree_is_sorted_local expected_result must match direct child ordering")
    elif algorithm == "binary_tree_path_sum":
        valid = (len(values) >= 2 and 0 <= values[1] <= 63
                 and len(values) == 2 + 3 * values[1])
        if valid:
            node_count = values[1]
            nodes = [values[index:index + 3] for index in range(2, len(values), 3)]
            valid = all(-(2**31) <= row[0] <= 2**31 - 1
                        and all(-1 <= child < node_count for child in row[1:]) for row in nodes)
        if not valid:
            expected_from_source = -1
        elif node_count == 0:
            expected_from_source = 0
        else:
            parents = [0] * node_count
            for _value, left, right in nodes:
                for child in (left, right):
                    if child >= 0:
                        parents[child] += 1
            valid = parents[0] == 0 and all(parents[index] == 1 for index in range(1, node_count))
            if valid:
                stack = [0]
                seen: set[int] = set()
                while stack:
                    node = stack.pop()
                    if node in seen:
                        valid = False
                        break
                    seen.add(node)
                    stack.extend(child for child in nodes[node][1:] if child >= 0)
                valid = valid and len(seen) == node_count
            if not valid:
                expected_from_source = -1
            else:
                expected_from_source = 0
                for start in range(node_count):
                    path_stack = [(start, nodes[start][0])]
                    while path_stack:
                        node, total = path_stack.pop()
                        if total == values[0]:
                            expected_from_source += 1
                        _value, left, right = nodes[node]
                        if left >= 0:
                            path_stack.append((left, total + nodes[left][0]))
                        if right >= 0:
                            path_stack.append((right, total + nodes[right][0]))
        if expected != expected_from_source:
            raise ValueError("binary_tree_path_sum expected_result must count every target-sum downward path")
    elif algorithm == "kth_smallest":
        valid = (len(values) >= 2 and 1 <= values[0] <= 256 and 1 <= values[1] <= values[0]
                 and len(values) == 2 + values[0]
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[2:]))
        expected_from_source = sorted(values[2:])[values[1] - 1] if valid else I64_MIN
        if expected != expected_from_source:
            raise ValueError("kth_smallest expected_result must match the bounded one-based order statistic")
    elif algorithm == "tree_height":
        valid = (len(values) >= 1 and 1 <= values[0] <= 1023
                 and len(values) == 2 * values[0] - 1)
        if valid:
            node_count = values[0]
            edges = list(zip(values[1::2], values[2::2]))
            valid = (len(edges) == node_count - 1
                     and all(1 <= left <= node_count and 1 <= right <= node_count and left != right
                             for left, right in edges))
        if not valid:
            expected_from_source = -1
        else:
            adjacency = [[] for _ in range(node_count + 1)]
            for left, right in edges:
                adjacency[left].append(right)
                adjacency[right].append(left)
            stack = [(1, 1, 0)]
            seen = {1}
            expected_from_source = 1
            while stack:
                node, height, parent = stack.pop()
                expected_from_source = max(expected_from_source, height)
                for neighbor in adjacency[node]:
                    if neighbor == parent:
                        continue
                    if neighbor in seen:
                        valid = False
                        break
                    seen.add(neighbor)
                    stack.append((neighbor, height + 1, node))
                if not valid:
                    break
            if not valid or len(seen) != node_count:
                expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("tree_height expected_result must match the root-1 DFS height in nodes")
    elif algorithm in {"polynomial_evaluation", "polynomial_evaluation_direct"}:
        valid = (len(values) >= 2 and 0 <= values[0] <= 8 and len(values) == 2 + values[0]
                 and -10 <= values[1] <= 10
                 and all(-1000 <= coefficient <= 1000 for coefficient in values[2:]))
        if not valid:
            expected_from_source = I64_MIN
        else:
            x = values[1]
            if algorithm == "polynomial_evaluation_direct":
                expected_from_source = sum(coefficient * (x ** index)
                                           for index, coefficient in enumerate(values[2:]))
            else:
                expected_from_source = 0
                for coefficient in reversed(values[2:]):
                    expected_from_source = expected_from_source * x + coefficient
        if expected != expected_from_source:
            method = "direct power summation" if algorithm == "polynomial_evaluation_direct" else "Horner evaluation"
            raise ValueError(f"{algorithm} expected_result must match bounded {method}")
    elif algorithm == "subset_sum_dynamic":
        valid = (1 <= len(values) <= 17 and -80 <= values[0] <= 80
                 and all(-20 <= value <= 20 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            target, items = values[0], tuple(values[1:])

            @lru_cache(maxsize=None)
            def has_subset(index: int, remaining: int) -> bool:
                if remaining == 0:
                    return True
                if index == len(items):
                    return False
                return has_subset(index + 1, remaining - items[index]) or has_subset(index + 1, remaining)

            expected_from_source = int(has_subset(0, target))
        if expected != expected_from_source:
            raise ValueError("subset_sum_dynamic expected_result does not match memoized subset existence")
    elif algorithm == "hash_sdbm":
        valid = 1 <= len(values) <= 64 and all(1 <= byte <= 127 for byte in values)
        if not valid:
            expected_from_source = -1
        else:
            hash_value = 0
            for byte in values:
                hash_value = (byte + (hash_value << 6) + (hash_value << 16) - hash_value) & (2**64 - 1)
            expected_from_source = hash_value if hash_value < 2**63 else hash_value - 2**64
        if expected != expected_from_source:
            raise ValueError("hash_sdbm expected_result must be the signed i64 interpretation of the SDBM hash")
    elif algorithm == "rotated_binary_search":
        valid_shape = (
            2 <= len(values) <= 258
            and 0 <= values[0] <= 256
            and len(values) == values[0] + 2
        )
        if not valid_shape:
            expected_from_source = -2
        elif values[0] == 0:
            expected_from_source = -1
        else:
            count = values[0]
            items = values[1:1 + count]
            key = values[-1]
            if (any(not -(2**31) <= value <= 2**31 - 1 for value in (*items, key))):
                expected_from_source = -2
            else:
                drops = sum(items[index - 1] > items[index] for index in range(1, count))
                if drops > 1 or (drops == 1 and items[-1] > items[0]):
                    expected_from_source = -2
                else:
                    left, right = 0, count - 1
                    expected_from_source = -1
                    while left <= right:
                        middle = left + (right - left) // 2
                        middle_value = items[middle]
                        if key == middle_value:
                            expected_from_source = middle
                            break
                        if items[left] == middle_value == items[right]:
                            left += 1
                            right -= 1
                            continue
                        if items[left] <= middle_value:
                            if items[left] <= key < middle_value:
                                right = middle - 1
                            else:
                                left = middle + 1
                        elif middle_value < key <= items[right]:
                            left = middle + 1
                        else:
                            right = middle - 1
        if expected != expected_from_source:
            raise ValueError("rotated_binary_search expected_result must match the duplicate-aware rotated search")
    elif algorithm == "average_mode":
        valid = 1 <= len(values) <= 64 and all(0 <= value <= 1000 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            frequencies: dict[int, int] = {}
            for value in values:
                frequencies[value] = frequencies.get(value, 0) + 1
            maximum = max(frequencies.values())
            leaders = [value for value, count in frequencies.items() if count == maximum]
            expected_from_source = leaders[0] if len(leaders) == 1 else -1
        if expected != expected_from_source:
            raise ValueError("average_mode expected_result must match the unique mode in the bounded input")
    elif algorithm == "same_trees_check":
        expected_from_source = same_trees_expected(values)
        if expected != expected_from_source:
            raise ValueError("same_trees_check expected_result must match BFS structural/value equality")
    elif algorithm == "characters_same":
        valid = len(values) <= 256 and all(0 <= value <= 127 for value in values)
        expected_from_source = -1 if not valid else int(not values or all(value == values[0] for value in values))
        if expected != expected_from_source:
            raise ValueError("characters_same expected_result must match the ASCII all-equal predicate")
    elif algorithm == "barcode_validator":
        if len(values) != 2 or values[0] not in (0, 1) or values[1] < 0:
            expected_from_source = -1
        else:
            operation, barcode = values
            remaining = barcode // 10
            weight, total = 3, 0
            while remaining:
                total += (remaining % 10) * weight
                weight = 1 if weight == 3 else 3
                remaining //= 10
            check_digit = (10 - total % 10) % 10
            expected_from_source = (check_digit if operation == 0 else
                                    int(len(str(barcode)) == 13 and barcode % 10 == check_digit))
        if expected != expected_from_source:
            raise ValueError("barcode_validator expected_result must match the alternating 3/1 checksum")
    elif algorithm == "max_product_subarray":
        valid = len(values) <= 9 and all(-10 <= value <= 10 for value in values)
        if not valid:
            expected_from_source = I64_MIN
        elif not values:
            expected_from_source = 0
        else:
            maximum_ending = minimum_ending = best = values[0]
            for value in values[1:]:
                candidates = (value, maximum_ending * value, minimum_ending * value)
                maximum_ending, minimum_ending = max(candidates), min(candidates)
                best = max(best, maximum_ending)
            expected_from_source = best
        if expected != expected_from_source:
            raise ValueError("max_product_subarray expected_result must match the bounded max/min recurrence")
    elif algorithm == "prefix_sum2_d":
        invalid = I64_MIN
        if len(values) < 7 or not (1 <= values[0] <= 16 and 1 <= values[1] <= 16):
            expected_from_source = invalid
        else:
            rows, columns = values[0], values[1]
            query = 2 + rows * columns
            if len(values) != query + 4:
                expected_from_source = invalid
            else:
                row1, col1, row2, col2 = values[query:query + 4]
                cells = values[2:query]
                valid = (all(-1000 <= value <= 1000 for value in cells)
                         and 0 <= row1 <= row2 < rows
                         and 0 <= col1 <= col2 < columns)
                if not valid:
                    expected_from_source = invalid
                else:
                    prefix = [[0] * (columns + 1) for _ in range(rows + 1)]
                    for row in range(rows):
                        for column in range(columns):
                            value = cells[row * columns + column]
                            prefix[row + 1][column + 1] = (value + prefix[row][column + 1]
                                                            + prefix[row + 1][column] - prefix[row][column])
                    expected_from_source = (prefix[row2 + 1][col2 + 1] - prefix[row1][col2 + 1]
                                            - prefix[row2 + 1][col1] + prefix[row1][col1])
        if expected != expected_from_source:
            raise ValueError("prefix_sum2_d expected_result must match the bounded padded prefix-table recurrence")
    elif algorithm == "adtfraction":
        if len(values) != 5 or any(not -100000 <= value <= 100000 for value in values):
            raise ValueError("adtfraction requires five values in [-100000, 100000]")
        operation, numerator, denominator, other_numerator, other_denominator = values
        def i32(value: int) -> int:
            value &= 0xFFFFFFFF
            return value - 0x100000000 if value >= 0x80000000 else value
        def packed_fraction(n: int, d: int) -> int:
            return i32(n) * 0x100000000 + (i32(d) & 0xFFFFFFFF)
        if operation == 0 and denominator != 0 and other_denominator != 0:
            result_denominator = i32(denominator * other_denominator)
            expected_from_source = (-1 if result_denominator == 0 else packed_fraction(
                i32(denominator * other_numerator + numerator * other_denominator), result_denominator))
        elif operation == 1 and denominator != 0:
            expected_from_source = packed_fraction(i32(numerator * other_numerator), denominator)
        elif operation == 2 and denominator != 0 and other_denominator != 0:
            result_denominator = i32(denominator * other_denominator)
            expected_from_source = (-1 if result_denominator == 0 else
                                    packed_fraction(i32(numerator * other_numerator), result_denominator))
        elif operation == 3 and numerator != 0:
            expected_from_source = packed_fraction(denominator, numerator)
        elif operation == 4 and denominator != 0:
            left = struct.unpack("<f", struct.pack("<f", float(numerator)))[0]
            right = struct.unpack("<f", struct.pack("<f", float(denominator)))[0]
            value = struct.unpack("<f", struct.pack("<f", left / right))[0]
            expected_from_source = struct.unpack("<I", struct.pack("<f", value))[0]
        else:
            expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("adtfraction expected_result must match Java i32 arithmetic and binary32 value semantics")
    return values


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", required=True, type=Path)
    parser.add_argument("--workload", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--samples", type=int)
    parser.add_argument("--warmups", type=int)
    parser.add_argument("--repetitions", type=int)
    args = parser.parse_args()
    manifest = json.loads(args.build_manifest.read_text(encoding="utf-8"))
    if manifest.get("family") != "i64_array_scalar":
        parser.error("build manifest must declare the i64_array_scalar ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["i64_array_scalar_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/i64_array_scalar_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        parser.error("workload does not match the built array scalar algorithm")
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed the runner limits")
    if len({case["id"] for case in workload["cases"]}) != len(workload["cases"]):
        parser.error("workload case IDs must be unique")
    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    implementation = {key: manifest[key] for key in (
        "language", "source_path", "source_sha256", "compiler", "compiler_version", "build_flags")}
    implementation.update({"runner_source_sha256": binary["harness_sha256"],
                           "binary_sha256": binary["sha256"],
                           "build_command": "\n".join(shlex.join(command) for command in manifest["commands"])})
    environment = {"os": platform.system(), "os_release": platform.release(),
                   "architecture": platform.machine(), "cpu_model": platform.processor().strip() or None,
                   "logical_cpu_count": os.cpu_count(), "python_version": platform.python_version()}
    records = []
    for case in workload["cases"]:
        values = encode_case(case, algorithm)
        if case.get("input_length") not in (None, len(values)):
            raise ValueError(f"declared input length differs for {case['id']}")
        if len(values) > 1024:
            command = [str(executable), "--stdin", str(len(values)), str(case["expected_result"]),
                       str(samples), str(warmups), str(repetitions)]
            streamed_values = " ".join(map(str, values)) + "\n"
        else:
            command = [str(executable), str(len(values)), *map(str, values), str(case["expected_result"]),
                       str(samples), str(warmups), str(repetitions)]
            streamed_values = None
        completed = subprocess.run(command, input=streamed_values, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"array scalar runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        if raw["observed_result"] != case["expected_result"] or len(raw["samples_ns"]) != samples:
            raise ValueError(f"array scalar runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(values), "input_values": values,
                                     "case": case["id"], "target": None,
                                     "expected_result": case["expected_result"]},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "i64_array_scalar_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"],
                                        "observed_result": raw["observed_result"],
                                        "result_checksum": raw["result_checksum"]}})
    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
