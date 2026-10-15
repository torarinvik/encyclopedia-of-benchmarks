#!/usr/bin/env python3
"""Record a built read-only i64-array scalar benchmark."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import os
from pathlib import Path
import platform
import shlex
import struct
import subprocess
import sys
from functools import lru_cache
from fractions import Fraction

from build_abi import ROOT, sha256_file

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_SLIDING_WINDOW_INPUT_LENGTH = 100002
MAX_DOUBLE_LINEAR_SEARCH_INPUT_LENGTH = 100002


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
    max_input_length = (MAX_SLIDING_WINDOW_INPUT_LENGTH
                        if algorithm in {"min_sum_ksize_subarray", "max_sum_sliding_window"}
                        else MAX_DOUBLE_LINEAR_SEARCH_INPUT_LENGTH
                        if algorithm == "double_linear_search" else 100001)
    if (not isinstance(values, list) or len(values) > max_input_length
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or type(expected) is not int):
        raise ValueError(f"array scalar cases require up to {max_input_length} signed 64-bit values")
    if algorithm == "hopcroft_karp_cardinality":
        valid = (
            len(values) >= 3
            and 0 <= values[0] <= 64
            and 0 <= values[1] <= 64
            and 0 <= values[2] <= 4096
            and len(values) == 3 + 2 * values[2]
        )
        if valid:
            left_count, right_count, edge_count = values[:3]
            adjacency = [set() for _ in range(left_count)]
            for offset in range(3, len(values), 2):
                left, right = values[offset:offset + 2]
                if not 0 <= left < left_count or not 0 <= right < right_count:
                    valid = False
                    break
                adjacency[left].add(right)
        if not valid:
            expected_from_source = -1
        else:
            matched_left = [-1] * right_count

            def augment(left: int, seen_right: set[int]) -> bool:
                for right in sorted(adjacency[left]):
                    if right in seen_right:
                        continue
                    seen_right.add(right)
                    if matched_left[right] == -1 or augment(matched_left[right], seen_right):
                        matched_left[right] = left
                        return True
                return False

            expected_from_source = sum(
                1 for left in range(left_count) if augment(left, set())
            )
        if expected != expected_from_source:
            raise ValueError("hopcroft_karp_cardinality expected_result must match maximum bipartite matching cardinality")
    elif algorithm == "faraday_lenz_law":
        valid = (len(values) == 3 and -1_000_000_000 <= values[0] <= 1_000_000_000
                 and -1_000_000_000 <= values[1] <= 1_000_000_000
                 and 1 <= values[2] <= 1_000_000_000)
        if valid:
            numerator = -(values[0] - values[1]) * 10
            sign = -1 if numerator < 0 else 1
            quotient, remainder = divmod(abs(numerator), values[2])
            twice_remainder = 2 * remainder
            if twice_remainder > values[2] or (twice_remainder == values[2] and quotient % 2 == 1):
                quotient += 1
            expected_from_source = sign * quotient
        else:
            expected_from_source = I64_MIN
        if expected != expected_from_source:
            raise ValueError("faraday_lenz_law expected_result must match signed ties-to-even rounding in decivolts")
    elif algorithm == "fast_inverse_sqrt_java_check":
        valid = len(values) == 2
        expected_from_source = -1
        if valid:
            mode, raw_bits = values
            if mode == 0:
                valid = 8_388_608 <= raw_bits <= 2_139_095_039
                if valid:
                    def float32(value: float) -> float:
                        return struct.unpack("<f", struct.pack("<f", value))[0]

                    number = struct.unpack("<f", struct.pack("<I", raw_bits))[0]
                    xhalf = float32(0.5 * number)
                    seed = 0x5F3759DF - (raw_bits >> 1)
                    x = struct.unpack("<f", struct.pack("<I", seed))[0]
                    product = float32(float32(xhalf * x) * x)
                    correction = float32(1.5 - product)
                    approximation = float32(x * correction)
                    sqrt_value = float32(math.sqrt(number))
                    exact_value = float32(1.0 / sqrt_value)
                    expected_from_source = int(approximation == exact_value)
            elif mode == 1:
                valid = 4_503_599_627_370_496 <= raw_bits <= 9_218_868_437_227_405_311
                if valid:
                    number = struct.unpack("<d", struct.pack("<Q", raw_bits))[0]
                    xhalf = 0.5 * number
                    seed = 0x5FE6EC85E7DE30DA - (raw_bits >> 1)
                    approximation = struct.unpack("<d", struct.pack("<Q", seed))[0]
                    for _ in range(4):
                        product = (xhalf * approximation) * approximation
                        approximation = approximation * (1.5 - product)
                    approximation *= number
                    expected_from_source = int(approximation == 1.0 / math.sqrt(number))
            else:
                valid = False
        if not valid:
            expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("fast_inverse_sqrt_java_check expected_result must match the selected Java exact-equality overload")
    elif algorithm == "ncr_modulo_p":
        valid = (len(values) == 4 and 0 <= values[0] <= 64
                 and 2 <= values[1] <= 1009 and 0 <= values[2] <= values[0]
                 and 0 <= values[3] <= 64)
        expected_from_source = I64_MIN
        if valid:
            size, modulus, n, r = values
            factorials = [1]
            for index in range(1, size + 1):
                factorials.append((factorials[-1] * index) % modulus)
            if r > n:
                expected_from_source = 0
            elif r == 1:
                expected_from_source = n % modulus
            elif r == 0 or r == n:
                expected_from_source = 1
            else:
                denominator = (factorials[r] * factorials[n - r]) % modulus

                def extended_gcd(a: int, b: int) -> tuple[int, int, int]:
                    if a == 0:
                        return b, 0, 1
                    gcd, x1, y1 = extended_gcd(b % a, a)
                    return gcd, y1 - (b // a) * x1, x1

                gcd, coefficient, _ = extended_gcd(denominator, modulus)
                if gcd != 1:
                    expected_from_source = -1
                else:
                    inverse = (coefficient + modulus) % modulus
                    expected_from_source = (factorials[n] * inverse) % modulus
        if expected != expected_from_source:
            raise ValueError("ncr_modulo_p expected_result must match the bounded factorial-table and extended-Euclid source")
    elif algorithm == "anyto_any":
        expected_from_source = -1
        if len(values) == 3:
            encoded, source_base, destination_base = values
            if (0 <= encoded <= 999_999_999 and 2 <= source_base <= 10
                    and 2 <= destination_base <= 10):
                decimal_value = 0
                source_multiplier = 1
                valid = True
                while encoded > 0:
                    digit = encoded % 10
                    if digit >= source_base:
                        valid = False
                        break
                    decimal_value += digit * source_multiplier
                    source_multiplier *= source_base
                    encoded //= 10
                if valid:
                    result = 0
                    destination_multiplier = 1
                    while decimal_value > 0:
                        result += (decimal_value % destination_base) * destination_multiplier
                        decimal_value //= destination_base
                        if decimal_value > 0:
                            if destination_multiplier > 999_999_999 // 10:
                                valid = False
                                break
                            destination_multiplier *= 10
                    if valid:
                        expected_from_source = result
        if expected != expected_from_source:
            raise ValueError("anyto_any expected_result must match the bounded decimal-digit base conversion")
    elif algorithm == "apriori":
        valid = (len(values) >= 4 and 1 <= values[0] <= 64 and 1 <= values[1] <= 12
                 and 1 <= values[2] <= 1_000_000 and 0 <= values[3] <= 1_000_000
                 and len(values) == 4 + values[0])
        expected_from_source = -1
        if valid:
            transaction_count, item_count_value, support_ppm, confidence_ppm = values[:4]
            mask_limit = 1 << item_count_value
            transactions = values[4:]
            valid = all(0 <= transaction < mask_limit for transaction in transactions)
            if valid:
                supports: dict[int, int] = {}
                previous: set[int] = set()
                all_frequent: set[int] = set()
                for item in range(item_count_value):
                    candidate = 1 << item
                    support = sum((transaction & candidate) == candidate for transaction in transactions)
                    if support * 1_000_000 >= support_ppm * transaction_count:
                        supports[candidate] = support
                        previous.add(candidate)
                        all_frequent.add(candidate)
                for size in range(2, item_count_value + 1):
                    current: set[int] = set()
                    for candidate in range(1, mask_limit):
                        if candidate.bit_count() != size:
                            continue
                        if not all((candidate ^ (1 << item)) in previous
                                   for item in range(item_count_value) if candidate & (1 << item)):
                            continue
                        support = sum((transaction & candidate) == candidate for transaction in transactions)
                        if support * 1_000_000 >= support_ppm * transaction_count:
                            supports[candidate] = support
                            current.add(candidate)
                            all_frequent.add(candidate)
                    previous = current
                    if not current:
                        break
                expected_from_source = 0
                for candidate in all_frequent:
                    if candidate.bit_count() < 2:
                        continue
                    antecedent = (candidate - 1) & candidate
                    while antecedent:
                        if supports[candidate] * 1_000_000 >= confidence_ppm * supports[antecedent]:
                            expected_from_source += 1
                        antecedent = (antecedent - 1) & candidate
        if not valid:
            expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("apriori expected_result must match the frequent association-rule count")
    elif algorithm == "assignment_using_bitmask":
        valid = (len(values) >= 2 and 0 <= values[0] <= 10 and 0 <= values[1] <= 10
                 and len(values) == 2 + values[0])
        expected_from_source = -1
        if valid:
            people, tasks = values[:2]
            valid_task_mask = (1 << tasks) - 1
            allowed = values[2:]
            valid = all(0 <= mask <= valid_task_mask for mask in allowed)
            if valid:
                full_mask = (1 << people) - 1

                @lru_cache(maxsize=None)
                def count_assignments(mask: int, task: int) -> int:
                    if mask == full_mask:
                        return 1
                    if task == tasks:
                        return 0
                    total = count_assignments(mask, task + 1)
                    for person, task_mask in enumerate(allowed):
                        bit = 1 << person
                        if mask & bit == 0 and task_mask & (1 << task):
                            total += count_assignments(mask | bit, task + 1)
                    return total

                expected_from_source = count_assignments(0, 0)
        if expected != expected_from_source:
            raise ValueError("assignment_using_bitmask expected_result must match distinct eligible task assignments")
    elif algorithm == "arithmetic_coding":
        valid = (len(values) >= 2 and 1 <= values[0] <= 12 and len(values) == values[0] + 1
                 and all(0 <= symbol <= 255 for symbol in values[1:]))
        expected_from_source = -1
        if valid:
            count = values[0]
            frequency = [0] * 256
            for symbol in values[1:]:
                frequency[symbol] += 1
            cumulative = [0] * 257
            for symbol in range(256):
                cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol]
            low, high = Fraction(0), Fraction(1)
            for symbol in values[1:]:
                old_low = low
                interval = high - old_low
                low = old_low + interval * Fraction(cumulative[symbol], count)
                high = old_low + interval * Fraction(cumulative[symbol + 1], count)
            scaled = low * (count ** count)
            if scaled.denominator != 1:
                raise ValueError("arithmetic_coding exact interval did not scale to an integer")
            expected_from_source = scaled.numerator
        if expected != expected_from_source:
            raise ValueError("arithmetic_coding expected_result must be the exact scaled lower interval bound")
    elif algorithm == "ascending_priority_queue":
        valid = (len(values) >= 1 and 0 <= values[0] <= 512 and len(values) == 1 + 2 * values[0])
        expected_from_source = -1
        if valid:
            queue: list[int] = []
            removed_total = 0
            for operation_index in range(values[0]):
                opcode, payload = values[1 + 2 * operation_index:3 + 2 * operation_index]
                if opcode == 0:
                    if payload < -1_000_000 or payload > 1_000_000 or len(queue) >= 64:
                        valid = False
                        break
                    queue.append(payload)
                elif opcode == 1:
                    if payload != 0 or not queue:
                        valid = False
                        break
                    smallest = min(queue)
                    queue.remove(smallest)
                    removed_total += (operation_index + 1) * (smallest + 1_000_001)
                else:
                    valid = False
                    break
            if valid:
                expected_from_source = removed_total + sum(
                    position * (value + 1_000_001) for position, value in enumerate(queue, start=1)
                )
        if expected != expected_from_source:
            raise ValueError("ascending_priority_queue expected_result must match stable remove-min behavior")
    elif algorithm == "rod_cutting":
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
    elif algorithm == "count_letters":
        valid = (len(values) >= 2 and 0 <= values[1] <= 256
                 and len(values) == values[1] + 2
                 and all(65 <= value <= 90 or 97 <= value <= 122
                         for value in [values[0], *values[2:]]))
        if not valid:
            expected_from_source = -1
        else:
            query = values[0] | 32
            expected_from_source = sum((value | 32) == query for value in values[2:])
        if expected != expected_from_source:
            raise ValueError("count_letters expected_result must match the case-insensitive ASCII letter frequency")
    elif algorithm == "duplicate_brackets":
        valid = (len(values) >= 1 and 0 <= values[0] <= 256
                 and len(values) == values[0] + 1
                 and all(32 <= value <= 126 for value in values[1:]))
        if valid:
            depth = 0
            for byte in values[1:]:
                if byte == ord("("):
                    depth += 1
                elif byte == ord(")"):
                    depth -= 1
                    if depth < 0:
                        valid = False
                        break
            if depth != 0:
                valid = False
        if not valid:
            expected_from_source = -1
        else:
            stack: list[int] = []
            expected_from_source = 0
            for byte in values[1:]:
                if byte != ord(")"):
                    stack.append(byte)
                elif not stack or stack[-1] == ord("("):
                    expected_from_source = 1
                    break
                else:
                    while stack:
                        if stack.pop() == ord("("):
                            break
        if expected != expected_from_source:
            raise ValueError("duplicate_brackets expected_result must match the balanced printable-ASCII stack scan")
    elif algorithm == "minimum_size_subarray_sum":
        valid = (len(values) >= 2 and 1 <= values[0] <= 1_000_000
                 and 0 <= values[1] <= 256 and len(values) == values[1] + 2
                 and all(1 <= value <= 1_000_000 for value in values[2:]))
        if not valid:
            expected_from_source = -1
        else:
            target = values[0]
            items = values[2:]
            left = 0
            window_sum = 0
            shortest = len(items) + 1
            for right, value in enumerate(items):
                window_sum += value
                while window_sum >= target:
                    shortest = min(shortest, right - left + 1)
                    window_sum -= items[left]
                    left += 1
            expected_from_source = 0 if shortest > len(items) else shortest
        if expected != expected_from_source:
            raise ValueError("minimum_size_subarray_sum expected_result must match the positive-value sliding-window minimum")
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
    elif algorithm == "fletcher16":
        valid = len(values) <= 4096 and all(0 <= byte <= 127 for byte in values)
        if not valid:
            expected_from_source = -1
        else:
            sum1 = sum(values) % 255
            sum2 = sum((len(values) - index) * byte
                       for index, byte in enumerate(values)) % 255
            expected_from_source = (sum2 << 8) | sum1
        if expected != expected_from_source:
            raise ValueError("fletcher16 expected_result must match the bounded ASCII Fletcher-16 checksum")
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
    elif algorithm == "perimeter":
        if len(values) != 2 or not (3 <= values[0] <= 256 and 1 <= values[1] <= 255):
            expected_from_source = -1
        else:
            expected_from_source = values[0] * values[1]
        if expected != expected_from_source:
            raise ValueError("perimeter expected_result must match the bounded regular-polygon product")
    elif algorithm == "longest_common_substring":
        if len(values) < 2 or not (0 <= values[0] <= 256):
            expected_from_source = -1
        else:
            first_length = values[0]
            second_length_index = first_length + 1
            if second_length_index >= len(values):
                expected_from_source = -1
            else:
                second_length = values[second_length_index]
                valid = (0 <= second_length <= 256
                         and len(values) == first_length + second_length + 2)
                first = values[1:second_length_index]
                second = values[second_length_index + 1:]
                valid = valid and all(32 <= value <= 126 for value in first + second)
                if not valid:
                    expected_from_source = -1
                else:
                    suffix_lengths = [0] * (second_length + 1)
                    expected_from_source = 0
                    for first_byte in first:
                        for index in range(second_length, 0, -1):
                            if first_byte == second[index - 1]:
                                suffix_lengths[index] = suffix_lengths[index - 1] + 1
                                expected_from_source = max(expected_from_source, suffix_lengths[index])
                            else:
                                suffix_lengths[index] = 0
        if expected != expected_from_source:
            raise ValueError("longest_common_substring expected_result must match the bounded longest common contiguous substring length")
    elif algorithm == "volume":
        valid = (len(values) == 4
                 and all(0 <= value <= 1000 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            operation, a, b, c = values
            if operation == 0:
                expected_from_source = a * a * a if b == 0 and c == 0 else -1
            elif operation == 1:
                expected_from_source = a * b * c
            elif operation == 2:
                product = a * b * c
                expected_from_source = product // 2 if product % 2 == 0 else -1
            elif operation == 3:
                product = a * b * c
                expected_from_source = product // 3 if product % 3 == 0 else -1
            else:
                expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("volume expected_result must match the bounded exact-integer geometry selector")
    elif algorithm == "max_character":
        valid = 1 <= len(values) <= 256 and all(97 <= value <= 122 for value in values)
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
            raise ValueError("max_character expected_result must match the unique lowercase-ASCII mode")
    elif algorithm == "set_kth_bit":
        valid = (len(values) == 2 and 0 <= values[0] <= 2_147_483_647
                 and 0 <= values[1] <= 30)
        expected_from_source = (values[0] | (1 << values[1])) if valid else -1
        if expected != expected_from_source:
            raise ValueError("set_kth_bit expected_result must match the source-safe bit-set operation")
    elif algorithm == "binomial_calculate":
        valid = (len(values) == 2 and 0 <= values[0] <= 62
                 and 0 <= values[1] <= values[0])
        if not valid:
            expected_from_source = -1
        else:
            n, k = values
            if k > n // 2:
                k = n - k
            result = 1
            for i in range(1, k + 1):
                result *= n - k + i
                result //= i
            expected_from_source = result
        if expected != expected_from_source:
            raise ValueError("binomial_calculate expected_result must match the bounded multiplicative recurrence")
    elif algorithm == "is_spain_national_id":
        check_letters = "TRWAGMYFPDXBNJZSQVHLCKE"
        valid = (len(values) in (9, 10)
                 and all(0 <= value <= 127 for value in values)
                 and (len(values) != 10 or values[8] == ord("-")))
        if valid:
            valid = all(ord("0") <= value <= ord("9") for value in values[:8])
        if not valid:
            expected_from_source = -1
        else:
            number = 0
            for value in values[:8]:
                number = number * 10 + value - ord("0")
            letter = values[-1]
            if ord("a") <= letter <= ord("z"):
                letter -= ord("a") - ord("A")
            if not ord("A") <= letter <= ord("Z"):
                expected_from_source = -1
            else:
                expected_from_source = int(letter == ord(check_letters[number % 23]))
        if expected != expected_from_source:
            raise ValueError("is_spain_national_id expected_result must match the bounded modulus-23 check letter")
    elif algorithm == "is_polish_national_id":
        valid = (len(values) == 11 and all(48 <= value <= 57 for value in values))
        if not valid:
            expected_from_source = -1
        else:
            digits = [value - 48 for value in values]
            number = 0
            for digit in digits:
                number = number * 10 + digit
            month_code = digits[2] * 10 + digits[3]
            day = digits[4] * 10 + digits[5]
            month_valid = any(start <= month_code <= end
                              for start, end in ((1, 12), (21, 32), (41, 52), (61, 72), (81, 92)))
            if not 10_100_000 <= number <= 99_923_199_999 or not month_valid or not 1 <= day <= 31:
                expected_from_source = 0
            else:
                weights = (1, 3, 7, 9)
                subtotal = sum((digit * weights[index % 4]) % 10
                               for index, digit in enumerate(digits[:10]))
                expected_from_source = int(10 - subtotal % 10 == digits[10])
        if expected != expected_from_source:
            raise ValueError("is_polish_national_id expected_result must match the bounded PESEL field and checksum checks")
    elif algorithm == "hex_to_rgb":
        valid = (len(values) == 6
                 and all(48 <= value <= 57 or 65 <= value <= 70 or 97 <= value <= 102
                         for value in values))
        if not valid:
            expected_from_source = -1
        else:
            packed_rgb = 0
            for value in values:
                if 48 <= value <= 57:
                    nibble = value - 48
                elif 65 <= value <= 70:
                    nibble = value - 65 + 10
                else:
                    nibble = value - 97 + 10
                packed_rgb = (packed_rgb << 4) | nibble
            expected_from_source = packed_rgb
        if expected != expected_from_source:
            raise ValueError("hex_to_rgb expected_result must match the packed six-digit RGB value")
    elif algorithm == "kaprekar_constant":
        valid = (len(values) == 2 and 0 <= values[0] <= 9999 and 1 <= values[1] <= 16)
        if not valid:
            expected_from_source = -1
        elif values[0] == 6174:
            expected_from_source = 0
        else:
            current = values[0]
            expected_from_source = -1
            for iteration in range(1, values[1] + 1):
                digits = sorted((current // 1000, (current // 100) % 10,
                                 (current // 10) % 10, current % 10))
                ascending = digits[0] * 1000 + digits[1] * 100 + digits[2] * 10 + digits[3]
                descending = digits[3] * 1000 + digits[2] * 100 + digits[1] * 10 + digits[0]
                current = descending - ascending
                if current == 6174:
                    expected_from_source = iteration
                    break
                if current == 0:
                    break
        if expected != expected_from_source:
            raise ValueError("kaprekar_constant expected_result must match the bounded four-digit routine")
    elif algorithm == "find_max_recursion":
        valid = (1 <= len(values) <= 256
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values))
        expected_from_source = max(values) if valid else -1
        if expected != expected_from_source:
            raise ValueError("find_max_recursion expected_result must match the signed-i32 maximum")
    elif algorithm == "double_linear_search":
        safe_integer_max = 9_007_199_254_740_991
        valid = (len(values) >= 2 and 0 <= values[1] <= 100_000
                 and len(values) == values[1] + 2
                 and all(-safe_integer_max <= value <= safe_integer_max for value in values))
        if not valid:
            expected_from_source = -1
        else:
            target, items = values[0], values[2:]
            left, right = 0, len(items) - 1
            expected_from_source = -1
            while left <= right:
                if items[left] == target:
                    expected_from_source = left
                    break
                if items[right] == target:
                    expected_from_source = right
                    break
                left += 1
                right -= 1
        if expected != expected_from_source:
            raise ValueError("double_linear_search expected_result must match the left-then-right endpoint probe order")
    elif algorithm == "order_agnostic_binary_search":
        valid = (len(values) >= 2 and 1 <= values[1] <= 99_999
                 and len(values) == values[1] + 2
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values))
        if valid:
            target, items = values[0], values[2:]
            ascending = items[0] < items[-1]
            monotone = (all(left <= right for left, right in zip(items, items[1:])) if ascending
                        else all(left >= right for left, right in zip(items, items[1:])))
            valid = monotone
        if not valid:
            expected_from_source = -1
        else:
            left, right = 0, len(items) - 1
            expected_from_source = -1
            while left <= right:
                middle = left + (right - left) // 2
                if items[middle] == target:
                    expected_from_source = middle
                    break
                if ascending:
                    if items[middle] < target:
                        left = middle + 1
                    else:
                        right = middle - 1
                elif items[middle] < target:
                    right = middle - 1
                else:
                    left = middle + 1
        if expected != expected_from_source:
            raise ValueError("order_agnostic_binary_search expected_result must match the source midpoint search")
    elif algorithm == "minimum_cost_path":
        invalid = I64_MIN
        if (len(values) < 2 or not (1 <= values[0] <= 16 and 1 <= values[1] <= 16)
                or len(values) != 2 + values[0] * values[1]):
            expected_from_source = invalid
        else:
            rows, columns = values[:2]
            cells = values[2:]
            if any(not -(2**31) <= value <= 2**31 - 1 for value in cells):
                expected_from_source = invalid
            else:
                costs = [0] * columns
                for row in range(rows):
                    for column in range(columns):
                        value = cells[row * columns + column]
                        if row == 0 and column == 0:
                            costs[column] = value
                        elif row == 0:
                            costs[column] = costs[column - 1] + value
                        elif column == 0:
                            costs[column] += value
                        else:
                            costs[column] = min(costs[column], costs[column - 1]) + value
                expected_from_source = costs[-1]
        if expected != expected_from_source:
            raise ValueError("minimum_cost_path expected_result must match the bounded right/down path recurrence")
    elif algorithm == "is_ipv6_address_valid":
        valid_input = (len(values) >= 1 and 0 <= values[0] <= 256
                       and len(values) == values[0] + 1
                       and all(0 <= value <= 127 for value in values[1:]))
        if not valid_input:
            expected_from_source = -1
        else:
            address = bytes(values[1:])

            def valid_ipv6_group(group: bytes) -> bool:
                return 1 <= len(group) <= 4 and all(
                    48 <= byte <= 57 or 65 <= byte <= 70 or 97 <= byte <= 102
                    for byte in group
                )

            if not address:
                expected_from_source = 0
            elif ((address.startswith(b":") and not address.startswith(b"::"))
                  or (address.endswith(b":") and not address.endswith(b"::"))
                  or b":::" in address or address.count(b"::") > 1):
                expected_from_source = 0
            elif b"::" not in address:
                groups = address.split(b":")
                expected_from_source = int(len(groups) == 8 and all(valid_ipv6_group(group) for group in groups))
            else:
                left, right = address.split(b"::", 1)
                left_groups = [group for group in left.split(b":") if group] if left else []
                right_groups = [group for group in right.split(b":") if group] if right else []
                groups = left_groups + right_groups
                expected_from_source = int(len(groups) < 8 and all(valid_ipv6_group(group) for group in groups))
        if expected != expected_from_source:
            raise ValueError("is_ipv6_address_valid expected_result must match the pinned ASCII IPv6 subset")
    elif algorithm == "combination_sum_iv":
        invalid = I64_MIN
        if (len(values) < 2 or not (0 <= values[0] <= 16 and 0 <= values[1] <= 63)
                or len(values) != values[0] + 2):
            expected_from_source = invalid
        else:
            denominations = values[2:]
            if (any(not 1 <= value <= 63 for value in denominations)
                    or len(set(denominations)) != len(denominations)):
                expected_from_source = invalid
            else:
                target = values[1]
                ways = [0] * (target + 1)
                ways[0] = 1
                for total in range(1, target + 1):
                    for denomination in denominations:
                        if denomination <= total:
                            ways[total] += ways[total - denomination]
                expected_from_source = ways[target]
        if expected != expected_from_source:
            raise ValueError("combination_sum_iv expected_result must match the bounded ordered-sequence recurrence")
    elif algorithm == "min_sum_ksize_subarray":
        invalid = I64_MIN
        if (len(values) < 2 or not 0 <= values[0] <= 100000
                or not 0 <= values[1] <= 100000 or len(values) != values[0] + 2
                or any(not -10000 <= value <= 10000 for value in values[2:])):
            expected_from_source = invalid
        else:
            n, window_size = values[:2]
            array = values[2:]
            if window_size > n:
                expected_from_source = -1
            elif window_size == 0:
                expected_from_source = 0
            else:
                current = sum(array[:window_size])
                expected_from_source = current
                for index in range(window_size, n):
                    current += array[index] - array[index - window_size]
                    expected_from_source = min(expected_from_source, current)
        if expected != expected_from_source:
            raise ValueError("min_sum_ksize_subarray expected_result must match the bounded fixed-window minimum")
    elif algorithm == "maximum_sum_of_distinct_subarrays_with_length_k":
        invalid = I64_MIN
        valid = (len(values) >= 2 and 1 <= values[0] <= 8192
                 and 1 <= values[1] <= values[0] and len(values) == values[0] + 2
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[2:]))
        if not valid:
            expected_from_source = invalid
        else:
            n, window_size = values[:2]
            items = values[2:]
            frequencies: dict[int, int] = {}
            window_sum = 0
            expected_from_source = 0
            for index, value in enumerate(items):
                frequencies[value] = frequencies.get(value, 0) + 1
                window_sum += value
                if index >= window_size:
                    outgoing = items[index - window_size]
                    frequencies[outgoing] -= 1
                    if frequencies[outgoing] == 0:
                        del frequencies[outgoing]
                    window_sum -= outgoing
                if index >= window_size - 1 and len(frequencies) == window_size:
                    expected_from_source = max(expected_from_source, window_sum)
        if expected != expected_from_source:
            raise ValueError("maximum_sum_of_distinct_subarrays_with_length_k expected_result must match the distinct-window maximum")
    elif algorithm == "max_sum_sliding_window":
        invalid = I64_MIN
        if (len(values) < 2 or not 1 <= values[0] <= 100000
                or not 1 <= values[1] <= values[0] or len(values) != values[0] + 2
                or any(not -1000000000 <= value <= 1000000000 for value in values[2:])):
            expected_from_source = invalid
        else:
            n, window_size = values[:2]
            array = values[2:]
            current = sum(array[:window_size])
            expected_from_source = current
            for outgoing in range(n - window_size):
                current = current - array[outgoing] + array[outgoing + window_size]
                expected_from_source = max(expected_from_source, current)
        if expected != expected_from_source:
            raise ValueError("max_sum_sliding_window expected_result must match the bounded fixed-window maximum")
    elif algorithm == "max_non_adjacent_sum":
        valid = (1 <= len(values) <= 100000
                 and all(0 <= value <= 10000 for value in values))
        if not valid:
            expected_from_source = I64_MIN
        else:
            previous_two = 0
            previous_one = values[0]
            for value in values[1:]:
                current = max(previous_one, previous_two + value)
                previous_two, previous_one = previous_one, current
            expected_from_source = previous_one
        if expected != expected_from_source:
            raise ValueError("max_non_adjacent_sum expected_result must match the bounded non-adjacent recurrence")
    elif algorithm == "power_sum":
        if len(values) != 2 or not 1 <= values[0] <= 1000 or not 2 <= values[1] <= 10:
            expected_from_source = -1
        else:
            target, power = values
            ways = [0] * (target + 1)
            ways[0] = 1
            base = 1
            while base**power <= target:
                powered = base**power
                for subtotal in range(target, powered - 1, -1):
                    ways[subtotal] += ways[subtotal - powered]
                base += 1
            expected_from_source = ways[target]
        if expected != expected_from_source:
            raise ValueError("power_sum expected_result must match distinct-base power subset counting")
    elif algorithm == "duval":
        if len(values) > 4096 or any(not 0 <= value <= 127 for value in values):
            expected_from_source = -1
        elif not values:
            expected_from_source = 0
        else:
            length = len(values)
            index = 0
            answer = 0
            while index < length:
                answer = index
                j, k = index + 1, index
                while j < 2 * length and values[j % length] >= values[k % length]:
                    if values[k % length] < values[j % length]:
                        k = index
                    else:
                        k += 1
                    j += 1
                while index <= k:
                    index += j - k
            expected_from_source = answer
        if expected != expected_from_source:
            raise ValueError("duval expected_result must match the pinned least-cyclic-shift scan")
    elif algorithm == "find_min_recursion":
        valid = (1 <= len(values) <= 256
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values))
        expected_from_source = min(values) if valid else -1
        if expected != expected_from_source:
            raise ValueError("find_min_recursion expected_result must match the bounded recursive minimum")
    elif algorithm == "even_tree":
        invalid = I64_MIN
        if (len(values) < 2 or not 2 <= values[0] <= 100 or values[0] % 2 != 0
                or values[1] != values[0] - 1
                or len(values) != 2 + 2 * values[1]):
            expected_from_source = invalid
        else:
            vertex_count = values[0]
            adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
            valid = True
            for offset in range(2, len(values), 2):
                left, right = values[offset] - 1, values[offset + 1] - 1
                if (not 0 <= left < vertex_count or not 0 <= right < vertex_count
                        or left == right or right in adjacency[left]):
                    valid = False
                    break
                adjacency[left].append(right)
                adjacency[right].append(left)
            if not valid:
                expected_from_source = invalid
            else:
                parent = [-2] * vertex_count
                parent[0] = -1
                order: list[int] = []
                pending = [0]
                while pending and valid:
                    vertex = pending.pop()
                    order.append(vertex)
                    for neighbor in adjacency[vertex]:
                        if neighbor == parent[vertex]:
                            continue
                        if parent[neighbor] != -2:
                            valid = False
                            break
                        parent[neighbor] = vertex
                        pending.append(neighbor)
                if not valid or len(order) != vertex_count:
                    expected_from_source = invalid
                else:
                    subtree_sizes = [1] * vertex_count
                    cuts = 0
                    for vertex in reversed(order):
                        if parent[vertex] >= 0:
                            subtree_sizes[parent[vertex]] += subtree_sizes[vertex]
                        if subtree_sizes[vertex] % 2 == 0:
                            cuts += 1
                    expected_from_source = cuts - 1
        if expected != expected_from_source:
            raise ValueError("even_tree expected_result must match the bounded root-at-one subtree parity count")
    elif algorithm == "horspool_search":
        invalid = -2
        if len(values) < 2:
            expected_from_source = invalid
        else:
            text_length, pattern_length = values[:2]
            valid = (0 <= text_length <= 512 and 0 <= pattern_length <= 64
                     and len(values) == 2 + text_length + pattern_length
                     and all(0 <= value <= 127 for value in values[2:]))
            if not valid:
                expected_from_source = invalid
            elif pattern_length == 0 or pattern_length > text_length:
                expected_from_source = -1
            else:
                text = values[2:2 + text_length]
                pattern = values[2 + text_length:]
                shifts: dict[int, int] = {}
                for index in range(pattern_length - 2, -1, -1):
                    shifts.setdefault(pattern[index], pattern_length - 1 - index)
                text_index = pattern_length - 1
                expected_from_source = -1
                while text_index < text_length:
                    pattern_index = pattern_length - 1
                    while pattern_index >= 0:
                        text_value = text[text_index + pattern_index - (pattern_length - 1)]
                        if pattern[pattern_index] != text_value:
                            text_index += shifts.get(text[text_index], pattern_length)
                            break
                        pattern_index -= 1
                    if pattern_index == -1:
                        expected_from_source = text_index - pattern_length + 1
                        break
        if expected != expected_from_source:
            raise ValueError("horspool_search expected_result must match the bounded case-sensitive Horspool scan")
    elif algorithm == "temperature_conversion":
        if (len(values) != 2 or not 0 <= values[0] <= 15
                or not -1_000_000 <= values[1] <= 1_000_000):
            expected_from_source = I64_MIN
        else:
            operation, temperature = values
            if operation == 0:
                converted = (temperature * 9) / 5 + 32
            elif operation == 1:
                converted = temperature + 273.15
            elif operation == 2:
                converted = (temperature * 9) / 5 + 491.67
            elif operation == 3:
                converted = ((temperature - 32) * 5) / 9
            elif operation == 4:
                converted = ((temperature - 32) * 5) / 9 + 273.15
            elif operation == 5:
                converted = temperature + 459.67
            elif operation == 6:
                converted = temperature - 273.15
            elif operation == 7:
                converted = ((temperature - 273.15) * 9) / 5 + 32
            elif operation == 8:
                converted = (temperature * 9) / 5
            elif operation == 9:
                converted = ((temperature - 491.67) * 5) / 9
            elif operation == 10:
                converted = temperature - 459.67
            elif operation == 11:
                converted = (temperature * 5) / 9
            elif operation == 12:
                converted = temperature * 1.25
            elif operation == 13:
                converted = temperature * 2.25 + 32
            elif operation == 14:
                converted = temperature * 1.25 + 273.15
            else:
                converted = temperature * 2.25 + 32 + 459.67
            expected_from_source = math.floor(converted + 0.5)
        if expected != expected_from_source:
            raise ValueError("temperature_conversion expected_result must match the bounded JavaScript-rounded conversion")
    elif algorithm in {"doomsday", "weekday_by_month_offsets"}:
        if len(values) != 3 or not 100 <= values[0] <= 9999:
            expected_from_source = -1
        else:
            try:
                date = dt.date(values[0], values[1], values[2])
            except ValueError:
                expected_from_source = -1
            else:
                expected_from_source = (date.weekday() + 1) % 7
        if expected != expected_from_source:
            raise ValueError(f"{algorithm} expected_result must match the bounded Gregorian weekday")
    elif algorithm == "bankers_algorithm":
        invalid = -1
        if len(values) < 2:
            expected_from_source = invalid
        else:
            process_count, resource_count = values[:2]
            valid = (1 <= process_count <= 16 and 1 <= resource_count <= 8
                     and len(values) == 2 + resource_count + 2 * process_count * resource_count)
            if not valid:
                expected_from_source = invalid
            else:
                available_start = 2
                maximum_start = available_start + resource_count
                allocation_start = maximum_start + process_count * resource_count
                available = values[available_start:maximum_start]
                maximum = values[maximum_start:allocation_start]
                allocation = values[allocation_start:]
                valid = (all(0 <= value <= 100 for value in available + maximum + allocation)
                         and all(allocation[index] <= maximum[index]
                                 for index in range(process_count * resource_count)))
                if not valid:
                    expected_from_source = invalid
                else:
                    finished = [False] * process_count
                    completed = 0
                    while True:
                        progressed = False
                        for process in range(process_count):
                            if finished[process]:
                                continue
                            row_start = process * resource_count
                            if all(maximum[row_start + resource] - allocation[row_start + resource]
                                   <= available[resource] for resource in range(resource_count)):
                                for resource in range(resource_count):
                                    available[resource] += allocation[row_start + resource]
                                finished[process] = True
                                completed += 1
                                progressed = True
                        if completed == process_count:
                            expected_from_source = 1
                            break
                        if not progressed:
                            expected_from_source = 0
                            break
        if expected != expected_from_source:
            raise ValueError("bankers_algorithm expected_result must match the bounded index-ordered safety scan")
    elif algorithm == "bankers_algorithm_python_demo":
        invalid = -1
        if len(values) < 2:
            expected_from_source = invalid
        else:
            process_count, resource_count = values[:2]
            valid = (1 <= process_count <= 16 and 1 <= resource_count <= 8
                     and len(values) == 2 + resource_count + 2 * process_count * resource_count)
            if not valid:
                expected_from_source = invalid
            else:
                claim_start = 2
                allocation_start = claim_start + resource_count
                maximum_start = allocation_start + process_count * resource_count
                claims = values[claim_start:allocation_start]
                allocations = values[allocation_start:maximum_start]
                maximum = values[maximum_start:]
                valid = (all(0 <= value <= 100 for value in claims + allocations + maximum)
                         and all(allocations[index] <= maximum[index]
                                 for index in range(process_count * resource_count)))
                if valid:
                    allocated_by_resource = [
                        sum(allocations[process * resource_count + resource]
                            for process in range(process_count))
                        for resource in range(resource_count)
                    ]
                    valid = all(allocated_by_resource[resource] <= claims[resource]
                                for resource in range(resource_count))
                if not valid:
                    expected_from_source = invalid
                else:
                    available = [claims[resource] - allocated_by_resource[resource]
                                 for resource in range(resource_count)]
                    needs = [tuple(maximum[process * resource_count + resource]
                                   - allocations[process * resource_count + resource]
                                   for resource in range(resource_count))
                             for process in range(process_count)]
                    first_process_for_need: dict[tuple[int, ...], int] = {}
                    for process, need in enumerate(needs):
                        first_process_for_need.setdefault(need, process)
                    remaining = list(range(process_count))
                    while remaining:
                        selected_position = next(
                            (position for position, process in enumerate(remaining)
                             if all(needs[process][resource] <= available[resource]
                                    for resource in range(resource_count))),
                            None,
                        )
                        if selected_position is None:
                            expected_from_source = 0
                            break
                        selected_process = remaining.pop(selected_position)
                        release_process = first_process_for_need[needs[selected_process]]
                        for resource in range(resource_count):
                            available[resource] += allocations[release_process * resource_count + resource]
                    else:
                        expected_from_source = 1
        if expected != expected_from_source:
            raise ValueError("bankers_algorithm_python_demo expected_result must preserve first-index duplicate-need releases")
    elif algorithm == "unique_subsequences_count":
        if (not values or not 0 <= values[0] <= 30 or len(values) != values[0] + 1
                or any(not 0 <= value <= 127 for value in values[1:])):
            expected_from_source = -1
        else:
            codepoints = values[1:]
            suffix_counts = [0] * (len(codepoints) + 1)
            for start in range(len(codepoints) - 1, -1, -1):
                seen: set[int] = set()
                count = 0
                for index in range(start, len(codepoints)):
                    codepoint = codepoints[index]
                    if codepoint not in seen:
                        seen.add(codepoint)
                        count += 1 + suffix_counts[index + 1]
                suffix_counts[start] = count
            expected_from_source = suffix_counts[0]
        if expected != expected_from_source:
            raise ValueError("unique_subsequences_count expected_result must count distinct nonempty ASCII subsequences")
    elif algorithm == "unbounded_knapsack":
        if len(values) < 2:
            expected_from_source = -1
        else:
            item_count, capacity = values[:2]
            valid = (0 <= item_count <= 16 and 0 <= capacity <= 100
                     and len(values) == 2 + 2 * item_count)
            if not valid:
                expected_from_source = -1
            else:
                item_values = values[2:2 + item_count]
                item_weights = values[2 + item_count:]
                valid = (all(1 <= value <= 100 for value in item_values)
                         and all(1 <= weight <= 100 for weight in item_weights))
                if not valid:
                    expected_from_source = -1
                else:
                    best = [0] * (capacity + 1)
                    for value, weight in zip(item_values, item_weights):
                        for current_capacity in range(weight, capacity + 1):
                            best[current_capacity] = max(
                                best[current_capacity],
                                value + best[current_capacity - weight],
                            )
                    expected_from_source = best[capacity]
        if expected != expected_from_source:
            raise ValueError("unbounded_knapsack expected_result must match unlimited item reuse")
    elif algorithm in {"damerau_levenshtein_distance", "optimal_string_alignment_distance"}:
        if len(values) < 2:
            expected_from_source = -1
        else:
            left_length, right_length = values[:2]
            valid = (0 <= left_length <= 32 and 0 <= right_length <= 32
                     and len(values) == 2 + left_length + right_length
                     and all(0 <= value <= 127 for value in values[2:]))
            if not valid:
                expected_from_source = -1
            else:
                left = values[2:2 + left_length]
                right = values[2 + left_length:]
                if algorithm == "damerau_levenshtein_distance":
                    # Lowrance-Wagner unrestricted Damerau-Levenshtein recurrence.
                    rows, columns = left_length, right_length
                    sentinel = rows + columns
                    distances = [[0] * (columns + 2) for _ in range(rows + 2)]
                    distances[0][0] = sentinel
                    for row in range(rows + 1):
                        distances[row + 1][0] = sentinel
                        distances[row + 1][1] = row
                    for column in range(columns + 1):
                        distances[0][column + 1] = sentinel
                        distances[1][column + 1] = column
                    last_row = [0] * 128
                    for row in range(1, rows + 1):
                        last_match_column = 0
                        for column in range(1, columns + 1):
                            prior_row = last_row[right[column - 1]]
                            prior_column = last_match_column
                            substitution_cost = 1
                            if left[row - 1] == right[column - 1]:
                                substitution_cost = 0
                                last_match_column = column
                            distances[row + 1][column + 1] = min(
                                distances[row][column] + substitution_cost,
                                distances[row + 1][column] + 1,
                                distances[row][column + 1] + 1,
                                distances[prior_row][prior_column]
                                + (row - prior_row - 1) + 1 + (column - prior_column - 1),
                            )
                        last_row[left[row - 1]] = row
                    expected_from_source = distances[rows + 1][columns + 1]
                else:
                    # OSA permits a single local adjacent-transposition recurrence.
                    distances = [[0] * (right_length + 1) for _ in range(left_length + 1)]
                    for row in range(left_length + 1):
                        distances[row][0] = row
                    for column in range(right_length + 1):
                        distances[0][column] = column
                    for row in range(1, left_length + 1):
                        for column in range(1, right_length + 1):
                            substitution_cost = int(left[row - 1] != right[column - 1])
                            distances[row][column] = min(
                                distances[row - 1][column] + 1,
                                distances[row][column - 1] + 1,
                                distances[row - 1][column - 1] + substitution_cost,
                            )
                            if (row > 1 and column > 1
                                    and left[row - 1] == right[column - 2]
                                    and left[row - 2] == right[column - 1]):
                                distances[row][column] = min(
                                    distances[row][column], distances[row - 2][column - 2] + 1
                                )
                    expected_from_source = distances[left_length][right_length]
        if expected != expected_from_source:
            raise ValueError(f"{algorithm} expected_result must match its bounded ASCII edit-distance recurrence")
    elif algorithm == "connected_components":
        if len(values) < 2:
            expected_from_source = -1
        else:
            vertex_count, edge_count = values[:2]
            valid = (0 <= vertex_count <= 256 and 0 <= edge_count <= 512
                     and len(values) == 2 + 2 * edge_count)
            if valid:
                edges = values[2:]
                valid = all(1 <= endpoint <= vertex_count for endpoint in edges)
            if not valid:
                expected_from_source = -1
            else:
                adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
                for offset in range(0, len(edges), 2):
                    left, right = edges[offset] - 1, edges[offset + 1] - 1
                    adjacency[left].append(right)
                    adjacency[right].append(left)
                visited: set[int] = set()
                expected_from_source = 0
                for start in range(vertex_count):
                    if start in visited:
                        continue
                    expected_from_source += 1
                    visited.add(start)
                    pending = [start]
                    while pending:
                        vertex = pending.pop()
                        for neighbor in adjacency[vertex]:
                            if neighbor not in visited:
                                visited.add(neighbor)
                                pending.append(neighbor)
        if expected != expected_from_source:
            raise ValueError("connected_components expected_result must match the undirected DFS component count")
    elif algorithm == "dinic_maxflow":
        if len(values) < 4:
            expected_from_source = -1
        else:
            vertex_count, edge_count, source, sink = values[:4]
            valid = (2 <= vertex_count <= 16 and 0 <= edge_count <= 64
                     and len(values) == 4 + 3 * edge_count
                     and 1 <= source <= vertex_count and 1 <= sink <= vertex_count
                     and source != sink)
            if valid:
                edge_values = values[4:]
                valid = all(
                    1 <= edge_values[index] <= vertex_count
                    and 1 <= edge_values[index + 1] <= vertex_count
                    and edge_values[index] != edge_values[index + 1]
                    and 0 <= edge_values[index + 2] <= 100
                    for index in range(0, len(edge_values), 3)
                )
            if not valid:
                expected_from_source = -1
            else:
                adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
                residual = [[0] * vertex_count for _ in range(vertex_count)]
                for index in range(0, len(edge_values), 3):
                    left = edge_values[index] - 1
                    right = edge_values[index + 1] - 1
                    capacity = edge_values[index + 2]
                    residual[left][right] += capacity
                    if right not in adjacency[left]:
                        adjacency[left].append(right)
                    if left not in adjacency[right]:
                        adjacency[right].append(left)
                source -= 1
                sink -= 1
                total_flow = 0
                while True:
                    levels = [-1] * vertex_count
                    levels[source] = 0
                    pending = [source]
                    for vertex in pending:
                        for neighbor in adjacency[vertex]:
                            if residual[vertex][neighbor] > 0 and levels[neighbor] < 0:
                                levels[neighbor] = levels[vertex] + 1
                                pending.append(neighbor)
                    if levels[sink] < 0:
                        break
                    edge_cursor = [0] * vertex_count

                    def send_flow(vertex: int, available: int) -> int:
                        if vertex == sink:
                            return available
                        while edge_cursor[vertex] < len(adjacency[vertex]):
                            neighbor = adjacency[vertex][edge_cursor[vertex]]
                            if (levels[neighbor] == levels[vertex] + 1
                                    and residual[vertex][neighbor] > 0):
                                pushed = send_flow(
                                    neighbor,
                                    min(available, residual[vertex][neighbor]),
                                )
                                if pushed:
                                    residual[vertex][neighbor] -= pushed
                                    residual[neighbor][vertex] += pushed
                                    return pushed
                            edge_cursor[vertex] += 1
                        return 0

                    while True:
                        pushed = send_flow(source, 6_400)
                        if not pushed:
                            break
                        total_flow += pushed
                expected_from_source = total_flow
        if expected != expected_from_source:
            raise ValueError("dinic_maxflow expected_result must match the bounded directed maximum flow")
    elif algorithm == "max_product_of_three":
        invalid = I64_MIN
        if (len(values) < 1 or not 3 <= values[0] <= 128 or len(values) != values[0] + 1
                or any(not -1000 <= value <= 1000 for value in values[1:])):
            expected_from_source = invalid
        else:
            ordered = sorted(values[1:])
            largest_three = ordered[-3:]
            smallest_two = ordered[:2]
            expected_from_source = max(
                largest_three[0] * largest_three[1] * largest_three[2],
                ordered[-1] * smallest_two[0] * smallest_two[1],
            )
        if expected != expected_from_source:
            raise ValueError("max_product_of_three expected_result must match the bounded exact maximum triple product")
    elif algorithm == "find_the_highest_altitude":
        valid = (len(values) >= 1 and 0 <= values[0] <= 1024
                 and len(values) == values[0] + 1
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            altitude = 0
            expected_from_source = 0
            for gain in values[1:]:
                altitude += gain
                expected_from_source = max(expected_from_source, altitude)
        if expected != expected_from_source:
            raise ValueError("find_the_highest_altitude expected_result must match the bounded maximum prefix sum")
    elif algorithm == "boruvkas_minimum_spanning_tree":
        if len(values) < 2:
            expected_from_source = -1
        else:
            vertex_count, edge_count = values[:2]
            maximum_edges = vertex_count * (vertex_count - 1) // 2
            valid = (2 <= vertex_count <= 16 and vertex_count - 1 <= edge_count
                     and edge_count <= min(64, maximum_edges)
                     and len(values) == 2 + 3 * edge_count)
            edges: list[tuple[int, int, int]] = []
            seen_pairs: set[tuple[int, int]] = set()
            if valid:
                for index in range(2, len(values), 3):
                    left, right, weight = values[index:index + 3]
                    pair = (min(left, right), max(left, right))
                    if (not 1 <= left <= vertex_count or not 1 <= right <= vertex_count
                            or left == right or pair in seen_pairs or not 1 <= weight <= 100):
                        valid = False
                        break
                    seen_pairs.add(pair)
                    edges.append((weight, left - 1, right - 1))
            if not valid:
                expected_from_source = -1
            else:
                parent = list(range(vertex_count))
                rank = [0] * vertex_count

                def find_root(vertex: int) -> int:
                    while parent[vertex] != vertex:
                        parent[vertex] = parent[parent[vertex]]
                        vertex = parent[vertex]
                    return vertex

                expected_from_source = 0
                selected_edges = 0
                for weight, left, right in sorted(edges):
                    root_left, root_right = find_root(left), find_root(right)
                    if root_left == root_right:
                        continue
                    if rank[root_left] < rank[root_right]:
                        root_left, root_right = root_right, root_left
                    parent[root_right] = root_left
                    if rank[root_left] == rank[root_right]:
                        rank[root_left] += 1
                    expected_from_source += weight
                    selected_edges += 1
                    if selected_edges == vertex_count - 1:
                        break
                if selected_edges != vertex_count - 1:
                    expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("boruvkas_minimum_spanning_tree expected_result must match the bounded MST total")
    elif algorithm == "alternate_harmonic_series":
        valid = (len(values) >= 3 and 1 <= values[0] <= 1000
                 and len(values) == 1 + 2 * values[0])
        terms: list[tuple[int, int]] = []
        if valid:
            for index in range(1, len(values), 2):
                numerator, denominator = values[index:index + 2]
                if not -1000 <= numerator <= 1000 or numerator == 0 or not 1 <= denominator <= 1000:
                    valid = False
                    break
                terms.append((numerator, denominator))
        expected_from_source = -1
        if valid:
            expected_from_source = 1
            if len(terms) >= 3:
                reciprocal_magnitudes = [Fraction(denominator, abs(numerator))
                                         for numerator, denominator in terms]
                common_difference = reciprocal_magnitudes[1] - reciprocal_magnitudes[0]
                for index in range(2, len(terms)):
                    if ((terms[index - 1][0] < 0) == (terms[index][0] < 0)
                            or reciprocal_magnitudes[index] - reciprocal_magnitudes[index - 1]
                            != common_difference):
                        expected_from_source = 0
                        break
        if expected != expected_from_source:
            raise ValueError("alternate_harmonic_series expected_result must match the exact index-2 source predicate")
    elif algorithm == "alternating_harmonic_series":
        valid = (len(values) >= 1 and 0 <= values[0] <= 1000
                 and len(values) == 1 + 2 * values[0])
        terms: list[tuple[int, int]] = []
        if valid:
            for index in range(1, len(values), 2):
                numerator, denominator = values[index:index + 2]
                if not -1000 <= numerator <= 1000 or not 1 <= denominator <= 1000:
                    valid = False
                    break
                terms.append((numerator, denominator))
        expected_from_source = -1
        if valid:
            expected_from_source = int(all(
                abs(numerator * (index + 1) - (1 if index % 2 == 0 else -1) * denominator) * 1_000_000_000
                <= denominator * (index + 1)
                for index, (numerator, denominator) in enumerate(terms)
            ))
        if expected != expected_from_source:
            raise ValueError("alternating_harmonic_series expected_result must match the exact inclusive 1e-9 term comparison")
    elif algorithm == "brute_force_knapsack":
        valid = (len(values) >= 2 and 0 <= values[0] <= 512 and 0 <= values[1] <= 14
                 and len(values) == 2 + 2 * values[1])
        items: list[tuple[int, int]] = []
        if valid:
            for index in range(2, len(values), 2):
                weight, value = values[index:index + 2]
                if not 1 <= weight <= 4096 or not 0 <= value <= 100_000_000:
                    valid = False
                    break
                items.append((weight, value))
        expected_from_source = -1
        if valid:
            capacity = values[0]

            def maximize_value(item_index: int, remaining_capacity: int) -> int:
                if item_index == len(items) or remaining_capacity == 0:
                    return 0
                weight, value = items[item_index]
                without_item = maximize_value(item_index + 1, remaining_capacity)
                if weight > remaining_capacity:
                    return without_item
                with_item = value + maximize_value(item_index + 1, remaining_capacity - weight)
                return max(without_item, with_item)

            expected_from_source = maximize_value(0, capacity)
        if expected != expected_from_source:
            raise ValueError("brute_force_knapsack expected_result must match the bounded recursive include/exclude optimum")
    elif algorithm == "shortest_common_supersequence_length":
        valid = (len(values) >= 2 and 0 <= values[0] <= 255 and 0 <= values[1] <= 255
                 and len(values) == 2 + values[0] + values[1])
        expected_from_source = -1
        if valid:
            left_length, right_length = values[:2]
            left_sequence = values[2:2 + left_length]
            right_sequence = values[2 + left_length:]
            valid = all(0 <= value <= 127 for value in left_sequence + right_sequence)
            if valid:
                lcs = [[0] * (right_length + 1) for _ in range(left_length + 1)]
                for left_index, left_value in enumerate(left_sequence):
                    for right_index, right_value in enumerate(right_sequence):
                        if left_value == right_value:
                            lcs[left_index + 1][right_index + 1] = lcs[left_index][right_index] + 1
                        else:
                            lcs[left_index + 1][right_index + 1] = max(
                                lcs[left_index][right_index + 1],
                                lcs[left_index + 1][right_index],
                            )
                expected_from_source = left_length + right_length - lcs[left_length][right_length]
        if expected != expected_from_source:
            raise ValueError("shortest_common_supersequence_length expected_result must match the full-table LCS complement")
    elif algorithm == "luhn":
        valid = (len(values) >= 1 and 2 <= values[0] <= 64 and values[0] % 2 == 0
                 and len(values) == values[0] + 1
                 and all(0 <= digit <= 9 for digit in values[1:]))
        expected_from_source = -1
        if valid:
            checksum = 0
            for index, digit in enumerate(values[1:]):
                adjusted = digit * 2 if index % 2 == 0 else digit
                checksum += adjusted - 9 if adjusted > 9 else adjusted
            expected_from_source = int(checksum % 10 == 0)
        if expected != expected_from_source:
            raise ValueError("luhn expected_result must match the bounded even-length digit checksum")
    elif algorithm == "xs3_conversion":
        valid = len(values) == 2 and values[0] in (0, 1)
        expected_from_source = -1
        if valid:
            direction, value = values
            if direction == 0:
                valid = 0 <= value <= 2_147_483_647
                if valid:
                    remaining = value
                    decimal_place = 1
                    decoded = 0
                    while remaining > 0:
                        nibble = remaining & 0xF
                        if not 3 <= nibble <= 12:
                            valid = False
                            break
                        decoded += (nibble - 3) * decimal_place
                        decimal_place *= 10
                        remaining >>= 4
                    if valid:
                        expected_from_source = decoded
            else:
                valid = 0 <= value <= 9_999_999
                if valid:
                    remaining = value
                    packed = 0
                    hexadecimal_place = 1
                    while remaining > 0:
                        packed += (remaining % 10 + 3) * hexadecimal_place
                        remaining //= 10
                        hexadecimal_place *= 16
                    expected_from_source = packed
        if expected != expected_from_source:
            raise ValueError("xs3_conversion expected_result must match the bounded source-order packed XS-3 conversion")
    elif algorithm == "polygonal_numbers":
        valid = (len(values) == 2 and 0 <= values[0] <= 100_000_000
                 and 3 <= values[1] <= 64)
        expected_from_source = -1
        if valid:
            number, sides = values
            numerator = (sides - 2) * number * number - (sides - 4) * number
            expected_from_source = numerator // 2
        if expected != expected_from_source:
            raise ValueError("polygonal_numbers expected_result must match the bounded source formula")
    elif algorithm == "min_number_of_jumps":
        valid = 1 <= len(values) <= 64 and all(0 <= jump <= 64 for jump in values)
        expected_from_source = -1
        if valid:
            unreachable = 1_000_000_000_000
            minimum_jumps = [unreachable] * len(values)
            minimum_jumps[0] = 0
            for destination in range(1, len(values)):
                for source in range(destination):
                    if source + values[source] >= destination:
                        minimum_jumps[destination] = min(
                            minimum_jumps[destination], minimum_jumps[source] + 1
                        )
            expected_from_source = minimum_jumps[-1]
        if expected != expected_from_source:
            raise ValueError("min_number_of_jumps expected_result must match the bounded quadratic DP and sentinel")
    elif algorithm == "tonelli_shanks":
        valid = (len(values) == 2 and 3 <= values[1] <= 1_000_003
                 and values[1] % 2 == 1 and 0 <= values[0] < values[1])
        expected_from_source = -1
        if valid:
            residue, prime = values
            if residue == 0:
                expected_from_source = 0
            else:
                legendre_exponent = (prime - 1) // 2

                def legendre_symbol(value: int) -> int:
                    symbol = pow(value % prime, legendre_exponent, prime)
                    return -1 if symbol == prime - 1 else symbol

                if legendre_symbol(residue) == 1:
                    if prime % 4 == 3:
                        root = pow(residue, (prime + 1) // 4, prime)
                        expected_from_source = min(root, prime - root)
                    else:
                        exponent_q = prime - 1
                        power_of_two_s = 0
                        while exponent_q % 2 == 0:
                            exponent_q //= 2
                            power_of_two_s += 1
                        non_residue = 2
                        while non_residue < prime and legendre_symbol(non_residue) != -1:
                            non_residue += 1
                        if non_residue < prime:
                            modular_c = pow(non_residue, exponent_q, prime)
                            modular_r = pow(residue, (exponent_q + 1) // 2, prime)
                            modular_t = pow(residue, exponent_q, prime)
                            remaining_s = power_of_two_s
                            for _ in range(power_of_two_s):
                                if modular_t == 1:
                                    break
                                test_power = modular_t
                                least_i = 0
                                for candidate_i in range(1, remaining_s):
                                    test_power = pow(test_power, 2, prime)
                                    if test_power == 1:
                                        least_i = candidate_i
                                        break
                                else:
                                    break
                                modular_b = pow(modular_c, 1 << (remaining_s - least_i - 1), prime)
                                modular_r = modular_r * modular_b % prime
                                modular_c = pow(modular_b, 2, prime)
                                modular_t = modular_t * modular_c % prime
                                remaining_s = least_i
                            if modular_t == 1:
                                expected_from_source = min(modular_r, prime - modular_r)
        if expected != expected_from_source:
            raise ValueError("tonelli_shanks expected_result must match the bounded modular-root source algorithm")
    elif algorithm == "excel_title_to_column":
        valid = (len(values) >= 1 and 1 <= values[0] <= 12
                 and len(values) == values[0] + 1
                 and all(65 <= code <= 90 or 97 <= code <= 122 for code in values[1:]))
        expected_from_source = -1
        if valid:
            answer = 0
            power = 0
            for code in reversed(values[1:]):
                uppercase_code = code - 32 if code >= 97 else code
                answer += (uppercase_code - 64) * (26 ** power)
                power += 1
            expected_from_source = answer
        if expected != expected_from_source:
            raise ValueError("excel_title_to_column expected_result must match the bounded ASCII base-26 conversion")
    elif algorithm == "combinations":
        valid = (len(values) == 2 and 0 <= values[0] <= 60
                 and 0 <= values[1] <= values[0])
        expected_from_source = -1
        if valid:
            n, k = values
            expected_from_source = 1
            for index in range(k):
                expected_from_source = expected_from_source * (n - index) // (index + 1)
        if expected != expected_from_source:
            raise ValueError("combinations expected_result must match the bounded multiply-then-divide binomial recurrence")
    elif algorithm in {"cycle_check_directed_graph", "cycle_check_directed_graph_kahn"}:
        valid = (len(values) >= 1 and len(values) <= 65 and (len(values) - 1) % 2 == 0
                 and 0 <= values[0] <= 64 and (len(values) - 1) // 2 <= 32)
        expected_from_source = -1
        if valid:
            vertices = values[0]
            adjacency = [0] * vertices
            for index in range(1, len(values), 2):
                source, destination = values[index:index + 2]
                if not 0 <= source < vertices or not 0 <= destination < vertices:
                    valid = False
                    break
                adjacency[source] |= 1 << destination
            if valid and algorithm == "cycle_check_directed_graph":
                state = [0] * vertices

                def visit(node: int) -> bool:
                    state[node] = 1
                    for destination in range(vertices):
                        if adjacency[node] & (1 << destination):
                            if state[destination] == 1:
                                return True
                            if state[destination] == 0 and visit(destination):
                                return True
                    state[node] = 2
                    return False

                expected_from_source = int(any(
                    state[root] == 0 and visit(root) for root in range(vertices)
                ))
            elif valid:
                indegree = [0] * vertices
                for source in range(vertices):
                    for destination in range(vertices):
                        if adjacency[source] & (1 << destination):
                            indegree[destination] += 1
                queue = [vertex for vertex in range(vertices) if indegree[vertex] == 0]
                removed = 0
                for source in queue:
                    removed += 1
                    for destination in range(vertices):
                        if adjacency[source] & (1 << destination):
                            indegree[destination] -= 1
                            if indegree[destination] == 0:
                                queue.append(destination)
                expected_from_source = int(removed != vertices)
        if not valid:
            expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError(f"{algorithm} expected_result must match the bounded directed-graph cycle check")
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
