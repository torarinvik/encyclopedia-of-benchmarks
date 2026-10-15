#!/usr/bin/env python3
"""Record a byte-output benchmark over a signed 64-bit input array."""

from __future__ import annotations

import argparse
import datetime as dt
from functools import lru_cache
import hashlib
import json
import os
from pathlib import Path
import platform
import shlex
import struct
import subprocess
import sys

from build_abi import ROOT, sha256_file

MAX_INPUT_LENGTH = 4096
MAX_MATRIX_INPUT_LENGTH = 100002
MAX_SQUARE_STREAK_INPUT_LENGTH = 100001
MAX_OUTPUT_CAPACITY = 400004
MAX_SMALL_INPUT_LENGTH = 66
MAX_AFFINE_CIPHER_INPUT_LENGTH = 612
MAX_SQUARED_ARRAY_INPUT_LENGTH = 10000
MAX_SORT_ARRAY_BY_PARITY_INPUT_LENGTH = 5000
MAX_FIND_DUPLICATES_INPUT_LENGTH = 100000
MAX_REDUNDANT_CONNECTION_INPUT_LENGTH = 2000
MAX_A_STAR_INPUT_LENGTH = 4 + 256 + 2 * 4096
MAX_ACCOUNT_MERGE_INPUT_LENGTH = 100002
KEYPAD = {2: b"abc", 3: b"def", 4: b"ghi", 5: b"jkl", 6: b"mno",
          7: b"pqrs", 8: b"tuv", 9: b"wxyz"}


MORSE_CODE = {
    **dict(zip(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        (".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
         "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-",
         "..-", "...-", ".--", "-..-", "-.--", "--.."),
    )),
    **dict(zip(
        "0123456789",
        ("-----", ".----", "..---", "...--", "....-", ".....", "-....", "--...",
         "---..", "----."),
    )),
}


@lru_cache(maxsize=None)
def amicable_proper_divisor_sum(number: int) -> int:
    """Factor n and use sigma(n) to produce an oracle independent of the sieve."""
    if number <= 1:
        return 0
    remaining, sigma, factor = number, 1, 2
    while factor <= remaining // factor:
        if remaining % factor == 0:
            prime_power, term = 1, 1
            while remaining % factor == 0:
                remaining //= factor
                prime_power *= factor
                term += prime_power
            sigma *= term
        factor = 3 if factor == 2 else factor + 2
    if remaining > 1:
        sigma *= remaining + 1
    return sigma - number


def account_merge_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not values or len(values) > MAX_ACCOUNT_MERGE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    account_count = values[0]
    if not 0 <= account_count <= 64:
        return -1, b""
    accounts: list[tuple[bytes, list[bytes]]] = []
    emails: list[tuple[bytes, int]] = []
    position = 1
    for account_index in range(account_count):
        if position >= len(values) or not 1 <= values[position] <= 64:
            return -1, b""
        name_length = values[position]
        position += 1
        if name_length > len(values) - position:
            return -1, b""
        name_values = values[position:position + name_length]
        if any(not 32 <= byte <= 126 for byte in name_values):
            return -1, b""
        name = bytes(name_values)
        position += name_length
        if position >= len(values) or not 0 <= values[position] <= 1024:
            return -1, b""
        email_count = values[position]
        position += 1
        if email_count > 1024 - len(emails):
            return -1, b""
        account_emails = []
        for _ in range(email_count):
            if position >= len(values) or not 1 <= values[position] <= 64:
                return -1, b""
            email_length = values[position]
            position += 1
            if email_length > len(values) - position:
                return -1, b""
            email_values = values[position:position + email_length]
            if any(not 33 <= byte <= 126 for byte in email_values):
                return -1, b""
            email = bytes(email_values)
            account_emails.append(email)
            emails.append((email, account_index))
            position += email_length
        accounts.append((name, account_emails))
    if position != len(values):
        return -1, b""

    parent = list(range(account_count))
    rank = [0] * account_count

    def find(value: int) -> int:
        while parent[value] != value:
            parent[value] = parent[parent[value]]
            value = parent[value]
        return value

    def union(left: int, right: int) -> None:
        left_root, right_root = find(left), find(right)
        if left_root == right_root:
            return
        if rank[left_root] < rank[right_root]:
            parent[left_root] = right_root
        elif rank[left_root] > rank[right_root]:
            parent[right_root] = left_root
        else:
            parent[right_root] = left_root
            rank[left_root] += 1

    email_owner: dict[bytes, int] = {}
    for email, account_index in emails:
        previous = email_owner.get(email)
        if previous is None:
            email_owner[email] = account_index
        else:
            union(account_index, previous)

    groups: dict[int, list[bytes]] = {}
    for account_index, (name, _) in enumerate(accounts):
        root = find(account_index)
        if accounts[root][0] != name:
            return -1, b""
        groups.setdefault(root, [])
    for email, account_index in email_owner.items():
        groups[find(account_index)].append(email)
    ordered = [(accounts[root][0], sorted(group_emails), root)
               for root, group_emails in groups.items()]
    ordered.sort(key=lambda group: (group[0], 0 if not group[1] else 1,
                                    group[1][0] if group[1] else b"", group[2]))

    output = bytearray()

    def write_u16(value: int) -> None:
        output.extend(value.to_bytes(2, "little"))

    write_u16(len(ordered))
    for name, group_emails, _ in ordered:
        write_u16(len(name))
        write_u16(len(group_emails))
        output.extend(name)
        for email in group_emails:
            write_u16(len(email))
            output.extend(email)
    return len(output), bytes(output)


def expected_output(values: list[int], algorithm: str = "letter_combinations_of_phone_number") -> tuple[int, bytes]:
    if algorithm == "z_algorithm_search":
        if (len(values) < 2 or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= 2047 or not 0 <= values[1] <= 2047
                or len(values) != 2 + values[0] + values[1]
                or any(not 0 <= value <= 127 for value in values[2:])):
            return -1, b""
        text_length, pattern_length = values[:2]
        text = [value + 32 if 65 <= value <= 90 else value for value in values[2:2 + text_length]]
        pattern = [value + 32 if 65 <= value <= 90 else value for value in values[2 + text_length:]]
        if pattern_length == 0:
            positions = range(1, text_length + 2)
        else:
            positions = (start + 1 for start in range(text_length - pattern_length + 1)
                         if text[start:start + pattern_length] == pattern)
        encoded = bytearray()
        count = 0
        for position in positions:
            encoded.extend(position.to_bytes(4, "little"))
            count += 1
        return count, bytes(encoded)
    if algorithm == "adagrad":
        import struct

        input_scale = 1_000_000_000
        output_scale = 1_000_000
        max_steps = 256
        max_groups = 16
        if (not 6 <= len(values) <= 3 + 3 * max_steps
                or any(type(value) is not int for value in values)):
            return -1, b""
        steps, learning_rate_value, epsilon_value = values[:3]
        if (not 1 <= steps <= max_steps or len(values) != 3 + 3 * steps
                or not 1 <= learning_rate_value <= input_scale
                or not 1 <= epsilon_value <= 10_000_000):
            return -1, b""
        learning_rate = learning_rate_value / input_scale
        epsilon = epsilon_value / input_scale
        def adagrad_sqrt(value: float) -> float:
            if value <= 0.0:
                return 0.0
            root = value if value > 1.0 else 1.0
            for _ in range(80):
                root = 0.5 * (root + value / root)
            return root

        accumulated = [0.0] * max_groups
        output_values = []
        for offset in range(3, len(values), 3):
            group_id, parameter_value, gradient_value = values[offset:offset + 3]
            if (not 0 <= group_id < max_groups
                    or not -1_000_000_000_000_000 <= parameter_value <= 1_000_000_000_000_000
                    or not -1_000_000_000_000 <= gradient_value <= 1_000_000_000_000):
                return -1, b""
            parameter = parameter_value / input_scale
            gradient = gradient_value / input_scale
            accumulated[group_id] += gradient * gradient
            updated = parameter - learning_rate / (adagrad_sqrt(accumulated[group_id]) + epsilon) * gradient
            output_values.append(math.trunc(updated * output_scale))
        return steps, struct.pack("<" + "q" * steps, *output_values)

    if algorithm == "account_merge":
        return account_merge_output(values)
    if algorithm == "a_star_search":
        if (len(values) < 5 or len(values) > MAX_A_STAR_INPUT_LENGTH
                or any(type(value) is not int for value in values)):
            return -1, b""
        vertex_count, edge_count, source, target = values[:4]
        if (not 1 <= vertex_count <= 256 or not 0 <= edge_count <= 4096
                or not 0 <= source < vertex_count or not 0 <= target < vertex_count
                or len(values) != 4 + vertex_count + 2 * edge_count):
            return -1, b""
        heuristic = values[4:4 + vertex_count]
        if (any(not 0 <= value <= 1_000_000_000 for value in heuristic)
                or heuristic[target] != 0):
            return -1, b""
        edges = values[4 + vertex_count:]
        adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
        for offset in range(0, len(edges), 2):
            origin, neighbor = edges[offset:offset + 2]
            if not 0 <= origin < vertex_count or not 0 <= neighbor < vertex_count:
                return -1, b""
            if heuristic[origin] > heuristic[neighbor] + 1:
                return -1, b""
            adjacency[origin].append(neighbor)

        import heapq

        distances: list[int | None] = [None] * vertex_count
        parents = [-1] * vertex_count
        closed = [False] * vertex_count
        distances[source] = 0
        queue = [(heuristic[source], 0, source)]
        while queue:
            _, distance, vertex = heapq.heappop(queue)
            if closed[vertex] or distances[vertex] != distance:
                continue
            if vertex == target:
                break
            closed[vertex] = True
            for neighbor in adjacency[vertex]:
                if closed[neighbor]:
                    continue
                candidate = distance + 1
                if distances[neighbor] is None or candidate < distances[neighbor]:
                    distances[neighbor] = candidate
                    parents[neighbor] = vertex
                    heapq.heappush(queue, (candidate + heuristic[neighbor], candidate, neighbor))

        if distances[target] is None:
            return 0, b""
        if distances[target] > 30:
            return -1, b""
        path = []
        vertex = target
        while vertex != -1:
            path.append(vertex)
            if vertex == source:
                break
            vertex = parents[vertex]
        if not path or path[-1] != source:
            return -1, b""
        path.reverse()
        return len(path), bytes(path)

    if algorithm == "binary_addition":
        if (len(values) < 2 or len(values) > 4096
                or any(type(value) is not int for value in values)):
            return -1, b""
        first_length, second_length = values[:2]
        if (not 0 <= first_length <= 2047 or not 0 <= second_length <= 2047
                or len(values) != 2 + first_length + second_length):
            return -1, b""
        first = values[2:2 + first_length]
        second = values[2 + first_length:]
        if any(bit not in (0, 1) for bit in first + second):
            return -1, b""
        result = []
        carry = 0
        for offset in range(max(first_length, second_length)):
            left = first[-1 - offset] if offset < first_length else 0
            right = second[-1 - offset] if offset < second_length else 0
            total = left + right + carry
            result.append(48 + total % 2)
            carry = total // 2
        if carry:
            result.append(49)
        result.reverse()
        return len(result), bytes(result)

    if algorithm == "sudoku_solver":
        import struct

        if (len(values) != 81
                or any(type(value) is not int or not 0 <= value <= 9 for value in values)):
            return -1, b""
        board = list(values)
        rows = [0] * 9
        columns = [0] * 9
        boxes = [0] * 9
        for position, digit in enumerate(board):
            if digit == 0:
                continue
            row, column = divmod(position, 9)
            box = (row // 3) * 3 + column // 3
            bit = 1 << digit
            if rows[row] & bit or columns[column] & bit or boxes[box] & bit:
                return -1, b""
            rows[row] |= bit
            columns[column] |= bit
            boxes[box] |= bit

        def solve(position: int) -> bool:
            while position < 81 and board[position] != 0:
                position += 1
            if position == 81:
                return True
            row, column = divmod(position, 9)
            box = (row // 3) * 3 + column // 3
            for digit in range(1, 10):
                bit = 1 << digit
                if rows[row] & bit or columns[column] & bit or boxes[box] & bit:
                    continue
                board[position] = digit
                rows[row] |= bit
                columns[column] |= bit
                boxes[box] |= bit
                if solve(position + 1):
                    return True
                board[position] = 0
                rows[row] ^= bit
                columns[column] ^= bit
                boxes[box] ^= bit
            return False

        if not solve(0):
            return -1, b""
        return 81, struct.pack("<81i", *board)

    if algorithm == "invert_binary_tree":
        import struct

        max_nodes, max_height = 1023, 512
        if (not 1 <= len(values) <= 1 + 3 * max_nodes
                or any(type(value) is not int for value in values)
                or (len(values) - 1) % 3 != 0):
            return -1, b""
        node_count = (len(values) - 1) // 3
        root = values[0]
        if node_count == 0:
            return (0, b"") if root == -1 else (-1, b"")
        if not 0 <= root < node_count:
            return -1, b""
        nodes = [list(values[offset:offset + 3])
                 for offset in range(1, len(values), 3)]
        visited: set[int] = set()

        def validate(index: int, depth: int) -> bool:
            if index == -1:
                return True
            if not 0 <= index < node_count or depth > max_height or index in visited:
                return False
            visited.add(index)
            value, left, right = nodes[index]
            if (not -(2**31) <= value < 2**31
                    or left < -1 or right < -1
                    or left >= node_count or right >= node_count):
                return False
            return validate(left, depth + 1) and validate(right, depth + 1)

        if not validate(root, 1) or len(visited) != node_count:
            return -1, b""

        def invert(index: int) -> None:
            if index == -1:
                return
            nodes[index][1], nodes[index][2] = nodes[index][2], nodes[index][1]
            invert(nodes[index][1])
            invert(nodes[index][2])

        invert(root)
        flattened = [value for node in nodes for value in node]
        return node_count, struct.pack("<" + "q" * len(flattened), *flattened)

    if algorithm == "merge_two_binary_trees":
        import struct

        null_slot = -1_000_001
        if (len(values) < 2 or len(values) > 512
                or any(type(value) is not int for value in values)):
            return -1, b""
        first_count = values[0]
        if not 0 <= first_count <= 255:
            return -1, b""
        second_count_position = first_count + 1
        if second_count_position >= len(values):
            return -1, b""
        second_count = values[second_count_position]
        second_start = second_count_position + 1
        if not 0 <= second_count <= 255 or len(values) != second_start + second_count:
            return -1, b""
        first, second = values[1:second_count_position], values[second_start:]

        def valid_heap_tree(slots: list[int]) -> bool:
            return (all(value == null_slot or -100_000 <= value <= 100_000 for value in slots)
                    and all(index == 0 or slots[(index - 1) // 2] != null_slot or value == null_slot
                            for index, value in enumerate(slots)))

        if not valid_heap_tree(first) or not valid_heap_tree(second):
            return -1, b""
        merged = []
        for index in range(max(first_count, second_count)):
            left = first[index] if index < first_count else null_slot
            right = second[index] if index < second_count else null_slot
            if left == null_slot and right == null_slot:
                merged.append(null_slot)
            else:
                merged.append((0 if left == null_slot else left) + (0 if right == null_slot else right))
        while merged and merged[-1] == null_slot:
            merged.pop()
        node_count = sum(value != null_slot for value in merged)
        output = struct.pack("<" + "i" * len(merged), *merged) if merged else b""
        return node_count, output

    if algorithm == "online_stock_span":
        import struct

        if (not 2 <= len(values) <= 4096
                or any(type(value) is not int for value in values)):
            return -1, b""
        count, prices = values[0], values[1:]
        if count != len(prices) or not 1 <= count <= 4095 or any(not 1 <= price <= 100_000 for price in prices):
            return -1, b""
        spans = []
        decreasing: list[int] = []
        for index, price in enumerate(prices):
            while decreasing and prices[decreasing[-1]] <= price:
                decreasing.pop()
            spans.append(index - decreasing[-1] if decreasing else index + 1)
            decreasing.append(index)
        return count, struct.pack("<" + "q" * count, *spans)

    if algorithm == "ones_minus_zeros":
        import struct

        if (len(values) < 2 or len(values) > MAX_MATRIX_INPUT_LENGTH
                or any(type(value) is not int for value in values)
                or not 1 <= values[0] <= 100000 or not 1 <= values[1] <= 100000):
            return -1, b""
        rows, columns = values[:2]
        if rows > 100000 // columns:
            return -1, b""
        cells = rows * columns
        if cells > 100000 or len(values) != 2 + cells:
            return -1, b""
        grid = values[2:]
        if any(value not in (0, 1) for value in grid):
            return -1, b""
        row_ones = [sum(grid[row * columns:(row + 1) * columns]) for row in range(rows)]
        column_ones = [sum(grid[row * columns + column] for row in range(rows))
                       for column in range(columns)]
        output = b"".join(
            struct.pack("<i", 2 * row_ones[row] + 2 * column_ones[column] - rows - columns)
            for row in range(rows) for column in range(columns)
        )
        return cells, output

    if algorithm == "longest_square_streak":
        if (not 3 <= len(values) <= MAX_SQUARE_STREAK_INPUT_LENGTH
                or any(type(value) is not int for value in values)):
            return -1, b""
        count, numbers = values[0], values[1:]
        if (count != len(numbers) or not 2 <= count <= 100000
                or any(not 2 <= number <= 100000 for number in numbers)):
            return -1, b""
        present = set(numbers)
        longest = 0
        for number in present:
            length = 1
            square = number * number
            while square in present:
                length += 1
                square *= square
            longest = max(longest, length)
        return (longest if longest >= 2 else -1), b""

    if algorithm == "amicable_pairs_below":
        if (len(values) != 1 or type(values[0]) is not int
                or not 1 <= values[0] <= 8_000):
            return -1, b""

        import struct

        limit = values[0]
        pairs = []
        for smaller in range(2, limit):
            larger = amicable_proper_divisor_sum(smaller)
            if smaller < larger < limit and amicable_proper_divisor_sum(larger) == smaller:
                pairs.append((smaller, larger))
        output = b"".join(struct.pack("<II", smaller, larger)
                           for smaller, larger in pairs)
        return len(pairs), output

    if algorithm == "extended_euclidean_algorithm":
        if (len(values) != 2 or any(type(value) is not int or not 1 <= value <= 2**31 - 1
                                    for value in values)):
            return -1, b""
        def bezout(a: int, b: int) -> tuple[int, int, int]:
            if b == 0:
                return a, 1, 0
            gcd, x1, y1 = bezout(b, a % b)
            return gcd, y1, x1 - (a // b) * y1
        gcd, coefficient_a, coefficient_b = bezout(*values)
        import struct
        return 3, struct.pack("<iii", gcd, coefficient_a, coefficient_b)

    if algorithm == "morse_code":
        if len(values) > 682:
            return -1, b""
        encoded = []
        for value in values:
            if 97 <= value <= 122:
                value -= 32
            if not 48 <= value <= 57 and not 65 <= value <= 90:
                return -1, b""
            encoded.append(MORSE_CODE[chr(value)].encode("ascii"))
        output = b" ".join(encoded)
        return len(output), output

    if algorithm == "bst_from_preorder":
        if (not 1 <= len(values) <= 15
                or any(type(value) is not int or not -(2**31) <= value < 2**31 for value in values)):
            return -1, b""
        root: list | None = None
        for value in values:
            if root is None:
                root = [value, None, None]
                continue
            node = root
            while True:
                if value == node[0]:
                    return -1, b""
                side = 1 if value < node[0] else 2
                if node[side] is None:
                    node[side] = [value, None, None]
                    break
                node = node[side]

        preorder = []
        def collect(node: list | None) -> None:
            if node is None:
                return
            preorder.append(node[0])
            collect(node[1])
            collect(node[2])
        collect(root)
        if preorder != values:
            return -1, b""

        encoded = bytearray()
        def serialize(node: list | None) -> None:
            if node is None:
                encoded.append(0)
                return
            encoded.append(1)
            encoded.extend(node[0].to_bytes(4, "little", signed=True))
            serialize(node[1])
            serialize(node[2])
        serialize(root)
        return len(values), bytes(encoded)

    if algorithm in {"sorted_array_to_bst", "sorted_list_to_bst"}:
        linked_list_semantics = algorithm == "sorted_list_to_bst"
        if (len(values) > 64
                or any(type(value) is not int or not -(2**31) <= value < 2**31 for value in values)):
            return -1, b""
        midpoint_rule = "upper" if linked_list_semantics else "lower"
        if linked_list_semantics:
            invalid_order = any(values[index - 1] > values[index] for index in range(1, len(values)))
        else:
            invalid_order = any(values[index - 1] >= values[index] for index in range(1, len(values)))
        if invalid_order:
            return -1, b""
        encoded = bytearray()

        def serialize(start: int, end: int) -> None:
            if start == end:
                encoded.append(0)
                return
            middle = (start + (end - start) // 2 if midpoint_rule == "upper"
                      else start + (end - start - 1) // 2)
            encoded.append(1)
            encoded.extend(values[middle].to_bytes(4, "little", signed=True))
            serialize(start, middle)
            serialize(middle + 1, end)

        serialize(0, len(values))
        return len(values), bytes(encoded)

    if algorithm == "duplicate_zeros":
        if (len(values) > 64
                or any(type(value) is not int or not 0 <= value <= 1000 for value in values)):
            return -1, b""
        duplicated = []
        for value in values:
            if len(duplicated) == len(values):
                break
            duplicated.append(value)
            if value == 0 and len(duplicated) < len(values):
                duplicated.append(0)
        output = b"".join(value.to_bytes(4, "little", signed=True) for value in duplicated)
        return len(duplicated), output

    if algorithm == "minimum_operations_to_move_all_balls":
        if (len(values) > 256
                or any(type(value) is not int or value not in (0, 1) for value in values)):
            return -1, b""
        right_ones = sum(values)
        right_distance = sum(index for index, value in enumerate(values) if value == 1)
        left_ones = 0
        left_distance = 0
        output = bytearray()
        for value in values:
            if value == 1:
                right_ones -= 1
                left_ones += 1
            distance = left_distance + right_distance
            output.extend(distance.to_bytes(2, "little"))
            right_distance -= right_ones
            left_distance += left_ones
        return len(values), bytes(output)

    if algorithm == "plus_one":
        if (len(values) > 256
                or any(type(value) is not int or not 0 <= value <= 9 for value in values)
                or (len(values) > 1 and values[0] == 0)):
            return -1, b""
        number = 0
        for digit in values:
            number = number * 10 + digit
        output = str(number + 1).encode("ascii")
        return len(output), output

    if algorithm == "subset_combinations":
        from itertools import combinations
        if (not 1 <= len(values) <= 13 or any(type(value) is not int for value in values)
                or values[0] < 0):
            return -1, b""
        item_count, choose = len(values) - 1, values[0]
        if choose > item_count:
            return 0, b""
        masks = [sum(1 << index for index in selected)
                 for selected in combinations(range(item_count), choose)]
        output = b"".join(mask.to_bytes(2, "little") for mask in masks)
        return len(masks), output

    if algorithm == "subset_sum_enumerate":
        if (not 1 <= len(values) <= 9 or any(type(value) is not int for value in values)):
            return -1, b""
        target, items = values[0], values[1:]
        if not -512 <= target <= 512 or any(not -64 <= value <= 64 for value in items):
            return -1, b""
        masks = []
        for mask in range(1 << len(items)):
            if sum(value for index, value in enumerate(items) if (mask >> index) & 1) == target:
                masks.append(mask)
        return len(masks), bytes(masks)

    if algorithm == "next_greater_nodes":
        if (not 1 <= len(values) <= MAX_INPUT_LENGTH
                or any(type(value) is not int or not 1 <= value <= 1_000_000_000
                       for value in values)):
            return -1, b""
        result = [0] * len(values)
        decreasing: list[int] = []
        for index in range(len(values) - 1, -1, -1):
            while decreasing and decreasing[-1] <= values[index]:
                decreasing.pop()
            if decreasing:
                result[index] = decreasing[-1]
            decreasing.append(values[index])
        output = b"".join(value.to_bytes(4, "little", signed=True) for value in result)
        return len(result), output

    if algorithm in {"a1z26_cipher", "a1z26_decipher"}:
        if (len(values) > MAX_SMALL_INPUT_LENGTH or any(type(value) is not int for value in values)):
            return -1, b""
        output = bytearray()
        if algorithm == "a1z26_cipher":
            for value in values:
                if 65 <= value <= 90:
                    output.append(value - 64)
                elif 97 <= value <= 122:
                    output.append(value - 96)
                else:
                    return -1, b""
        else:
            if any(not 1 <= value <= 26 for value in values):
                return -1, b""
            output.extend(96 + value for value in values)
        return len(output), bytes(output)

    if algorithm == "xor_cipher":
        if (not 3 <= len(values) <= MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int for value in values)):
            return -1, b""
        text_length, key_length = values[:2]
        if (not 0 <= text_length <= 63 or not 1 <= key_length <= 63
                or len(values) != 2 + text_length + key_length
                or any(not 0 <= value <= 255 for value in values[2:])):
            return -1, b""
        output = bytes(values[2 + index] ^ values[2 + text_length + index % key_length]
                       for index in range(text_length))
        return text_length, output

    if algorithm == "atbash_cipher":
        if (len(values) > MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
            return -1, b""
        output = bytearray(values)
        for index, value in enumerate(output):
            if 65 <= value <= 90:
                output[index] = 155 - value
            elif 97 <= value <= 122:
                output[index] = 219 - value
        return len(output), bytes(output)

    if algorithm == "affine_cipher":
        if (len(values) < 7 or len(values) > MAX_AFFINE_CIPHER_INPUT_LENGTH
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, key_a, key_b, alphabet_length = values[:4]
        if not 2 <= alphabet_length <= 95 or len(values) < 5 + alphabet_length:
            return -1, b""
        alphabet = values[4:4 + alphabet_length]
        text_length = values[4 + alphabet_length]
        text = values[5 + alphabet_length:]
        if (mode not in (0, 1) or not 0 <= key_a <= 1_000_000
                or not 0 <= key_b < alphabet_length or not 0 <= text_length <= 512
                or len(text) != text_length):
            return -1, b""
        if (any(not 32 <= value <= 126 for value in alphabet)
                or len(set(alphabet)) != alphabet_length
                or any(not 32 <= value <= 126 for value in text)
                or any(value not in set(alphabet) for value in text)):
            return -1, b""
        import math
        if math.gcd(key_a, alphabet_length) != 1:
            return -1, b""
        positions = {symbol: index for index, symbol in enumerate(alphabet)}
        multiplier = key_a % alphabet_length
        inverse = pow(multiplier, -1, alphabet_length) if mode == 1 else 0
        output = bytearray()
        for symbol in text:
            position = positions[symbol]
            if mode == 0:
                mapped = (position * multiplier + key_b) % alphabet_length
            else:
                mapped = ((position - key_b) * inverse) % alphabet_length
            output.append(alphabet[mapped])
        return text_length, bytes(output)

    if algorithm == "vigenere_cipher":
        if not 2 <= len(values) <= MAX_SMALL_INPUT_LENGTH or any(type(value) is not int for value in values):
            return -1, b""
        try:
            separator = values.index(0)
        except ValueError:
            return -1, b""
        if separator + 1 == len(values):
            return -1, b""
        message, key = values[:separator], values[separator + 1:]
        if (any(not 1 <= value <= 127 for value in message)
                or any(not (65 <= value <= 90 or 97 <= value <= 122) for value in key)):
            return -1, b""
        output = bytearray(message)
        key_index = 0
        for index, value in enumerate(message):
            if 65 <= value <= 90:
                key_value = key[key_index]
                if key_value >= 97:
                    key_value -= 32
                output[index] = 65 + (value - 65 + key_value - 65) % 26
                key_index = (key_index + 1) % len(key)
            elif 97 <= value <= 122:
                key_value = key[key_index]
                if key_value <= 90:
                    key_value += 32
                output[index] = 97 + (value - 97 + key_value - 97) % 26
                key_index = (key_index + 1) % len(key)
        return len(output), bytes(output)

    if algorithm == "run_length_encoding":
        if (len(values) > MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int or not 1 <= value <= 127
                       or 48 <= value <= 57 for value in values)):
            return -1, b""
        output = bytearray()
        index = 0
        while index < len(values):
            end = index + 1
            while end < len(values) and values[end] == values[index]:
                end += 1
            count = end - index
            output.extend(str(count).encode("ascii"))
            output.append(values[index])
            index = end
        return len(output), bytes(output)

    if algorithm == "to_lower_case":
        if (len(values) > MAX_INPUT_LENGTH
                or any(type(value) is not int or not 1 <= value <= 127 for value in values)):
            return -1, b""
        output = bytes(value + 32 if 65 <= value <= 90 else value for value in values)
        return len(output), output

    if algorithm == "acronym":
        if (len(values) > 79
                or any(type(value) is not int or not 1 <= value <= 127 for value in values)):
            return -1, b""
        output = bytearray()
        at_token_start = True
        for value in values:
            if value == 32:
                at_token_start = True
            elif at_token_start:
                output.append(value - 32 if 97 <= value <= 122 else value)
                at_token_start = False
        return len(output), bytes(output)

    if algorithm == "collatz_sequence":
        if (len(values) != 1 or type(values[0]) is not int
                or not 1 <= values[0] <= 1_000_000):
            return -1, b""
        sequence = [values[0]]
        current = values[0]
        while current != 1:
            current = current // 2 if current % 2 == 0 else 3 * current + 1
            sequence.append(current)
        output = struct.pack("<" + "q" * len(sequence), *sequence)
        return len(output), output

    if algorithm == "merge_two_sorted_lists":
        import struct

        if len(values) < 2 or len(values) > 1026:
            return -1, b""
        first_count, second_count = values[0], values[1]
        if (type(first_count) is not int or type(second_count) is not int
                or not 0 <= first_count <= 1024 or not 0 <= second_count <= 1024
                or first_count + second_count > 1024
                or len(values) != first_count + second_count + 2):
            return -1, b""
        first = values[2:2 + first_count]
        second = values[2 + first_count:]
        if any(type(value) is not int or not -(2**31) <= value < 2**31
               for value in (*first, *second)):
            return -1, b""
        if (any(first[index - 1] > first[index] for index in range(1, len(first)))
                or any(second[index - 1] > second[index] for index in range(1, len(second)))):
            return -1, b""
        merged = []
        first_index = second_index = 0
        while first_index < first_count and second_index < second_count:
            if first[first_index] <= second[second_index]:
                merged.append(first[first_index])
                first_index += 1
            else:
                merged.append(second[second_index])
                second_index += 1
        merged.extend(first[first_index:])
        merged.extend(second[second_index:])
        output = struct.pack("<" + "i" * len(merged), *merged) if merged else b""
        return len(merged), output

    if algorithm == "remove_duplicates_from_sorted_array":
        import struct

        if (len(values) > MAX_INPUT_LENGTH
                or any(type(value) is not int or not -(2**31) <= value < 2**31 for value in values)
                or any(values[index - 1] > values[index] for index in range(1, len(values)))):
            return -1, b""
        unique = [value for index, value in enumerate(values)
                  if index == 0 or value != values[index - 1]]
        output = struct.pack("<" + "i" * len(unique), *unique) if unique else b""
        return len(unique), output

    if algorithm == "remove_duplicates_from_sorted_list":
        import struct

        if (len(values) > 1024
                or any(type(value) is not int or not -(2**31) <= value < 2**31
                       for value in values)
                or any(values[index - 1] > values[index] for index in range(1, len(values)))):
            return -1, b""
        unique = []
        for value in values:
            if not unique or unique[-1] != value:
                unique.append(value)
        output = struct.pack("<" + "i" * len(unique), *unique) if unique else b""
        return len(unique), output

    if algorithm == "remove_all_duplicates_from_sorted_list":
        import struct

        if (len(values) > 1024
                or any(type(value) is not int or not -(2**31) <= value < 2**31
                       for value in values)
                or any(values[index - 1] > values[index] for index in range(1, len(values)))):
            return -1, b""
        unique = []
        index = 0
        while index < len(values):
            end = index + 1
            while end < len(values) and values[end] == values[index]:
                end += 1
            if end == index + 1:
                unique.append(values[index])
            index = end
        output = struct.pack("<" + "i" * len(unique), *unique) if unique else b""
        return len(unique), output

    if algorithm == "remove_element":
        import struct

        if (not 1 <= len(values) <= MAX_INPUT_LENGTH
                or any(type(value) is not int or not -(2**31) <= value < 2**31
                       for value in values)):
            return -1, b""
        target, items = values[0], values[1:]
        survivors = [value for value in items if value != target]
        output = struct.pack("<" + "i" * len(survivors), *survivors) if survivors else b""
        return len(survivors), output

    if algorithm == "remove_linked_list_elements":
        import struct

        if (not 1 <= len(values) <= 1025
                or any(type(value) is not int or not -(2**31) <= value < 2**31
                       for value in values)):
            return -1, b""
        target, *nodes = values
        survivors = [value for value in nodes if value != target]
        output = struct.pack("<" + "i" * len(survivors), *survivors) if survivors else b""
        return len(survivors), output

    if algorithm == "delete_middle_node":
        import struct

        if (len(values) > 1024
                or any(type(value) is not int or not -(2**31) <= value < 2**31
                       for value in values)):
            return -1, b""
        survivors = values[:len(values) // 2] + values[len(values) // 2 + 1:]
        output = struct.pack("<" + "i" * len(survivors), *survivors) if survivors else b""
        return len(survivors), output

    if algorithm == "move_zeroes":
        import struct

        if (len(values) > 4096
                or any(type(value) is not int or not -(2**31) <= value < 2**31
                       for value in values)):
            return -1, b""
        nonzero = [value for value in values if value != 0]
        moved = nonzero + [0] * (len(values) - len(nonzero))
        output = struct.pack("<" + "i" * len(moved), *moved) if moved else b""
        return len(moved), output

    if algorithm == "add_two_numbers":
        if (len(values) < 2 or len(values) > 2050
                or any(type(value) is not int for value in values)):
            return -1, b""
        first_length, second_length = values[:2]
        if (not 0 <= first_length <= 1024 or not 0 <= second_length <= 1024
                or len(values) != first_length + second_length + 2):
            return -1, b""
        first = values[2:2 + first_length]
        second = values[2 + first_length:]
        if any(not 0 <= digit <= 9 for digit in (*first, *second)):
            return -1, b""
        result = []
        carry = 0
        for index in range(max(first_length, second_length)):
            digit_sum = carry
            if index < first_length:
                digit_sum += first[index]
            if index < second_length:
                digit_sum += second[index]
            result.append(digit_sum % 10)
            carry = digit_sum // 10
        while carry:
            result.append(carry % 10)
            carry //= 10
        return len(result), bytes(result)

    if algorithm == "reverse_string_in_place":
        if (len(values) > 4096
                or any(type(value) is not int or not 0 <= value <= 255 for value in values)):
            return -1, b""
        return len(values), bytes(reversed(values))

    if algorithm == "reverse_only_letters":
        if (len(values) > 4096
                or any(type(value) is not int or not 32 <= value <= 126 for value in values)):
            return -1, b""
        output = bytearray(values)
        left, right = 0, len(output) - 1
        while left < right:
            if not (65 <= output[left] <= 90 or 97 <= output[left] <= 122):
                left += 1
                continue
            if not (65 <= output[right] <= 90 or 97 <= output[right] <= 122):
                right -= 1
                continue
            output[left], output[right] = output[right], output[left]
            left += 1
            right -= 1
        return len(output), bytes(output)

    if algorithm == "sort_array_by_parity":
        import struct

        if (len(values) > MAX_SORT_ARRAY_BY_PARITY_INPUT_LENGTH
                or any(type(value) is not int or not 0 <= value <= 5000 for value in values)):
            return -1, b""
        even_values = [value for value in values if value % 2 == 0]
        odd_values = [value for value in values if value % 2 != 0]
        ordered = even_values + list(reversed(odd_values))
        output = struct.pack("<" + "i" * len(ordered), *ordered) if ordered else b""
        return len(ordered), output

    if algorithm == "find_all_duplicates_in_array":
        import struct

        if (len(values) > MAX_FIND_DUPLICATES_INPUT_LENGTH
                or any(type(value) is not int or not 1 <= value <= len(values) for value in values)):
            return -1, b""
        frequencies: dict[int, int] = {}
        for value in values:
            frequencies[value] = frequencies.get(value, 0) + 1
            if frequencies[value] > 2:
                return -1, b""
        duplicates = sorted(value for value, frequency in frequencies.items() if frequency == 2)
        output = struct.pack("<" + "i" * len(duplicates), *duplicates) if duplicates else b""
        return len(duplicates), output

    if algorithm == "sum_even_after_queries":
        import struct

        if (len(values) < 5 or len(values) > MAX_INPUT_LENGTH
                or any(type(value) is not int for value in values)):
            return -1, b""
        number_count, query_count = values[:2]
        if not 1 <= number_count <= 1000 or not 1 <= query_count <= 1000:
            return -1, b""
        if len(values) != 2 + number_count + 2 * query_count:
            return -1, b""
        working = values[2:2 + number_count]
        if any(not 1 <= value <= 1000 for value in working):
            return -1, b""
        queries = list(zip(values[2 + number_count::2], values[3 + number_count::2]))
        if (len(queries) != query_count
                or any(not -1000 <= delta <= 1000 or not 0 <= index < number_count
                       for delta, index in queries)):
            return -1, b""
        output: list[int] = []
        for delta, index in queries:
            working[index] += delta
            output.append(sum(value for value in working if value % 2 == 0))
        encoded = struct.pack("<" + "i" * len(output), *output)
        return query_count, encoded

    if algorithm == "redundant_connection":
        import struct

        if (len(values) < 6 or len(values) > MAX_REDUNDANT_CONNECTION_INPUT_LENGTH
                or len(values) % 2 != 0
                or any(type(value) is not int for value in values)):
            return -1, b""
        vertex_count = len(values) // 2
        if not 3 <= vertex_count <= 1000:
            return -1, b""
        edges = list(zip(values[::2], values[1::2]))
        if any(not 1 <= endpoint <= vertex_count for edge in edges for endpoint in edge):
            return -1, b""
        if any(left == right for left, right in edges):
            return -1, b""
        parents = list(range(vertex_count + 1))

        def find_root(node: int) -> int:
            while parents[node] != node:
                parents[node] = parents[parents[node]]
                node = parents[node]
            return node

        redundant: tuple[int, int] | None = None
        redundant_count = 0
        for left, right in edges:
            left_root, right_root = find_root(left), find_root(right)
            if left_root == right_root:
                redundant = (left, right)
                redundant_count += 1
            else:
                parents[left_root] = right_root
        if redundant_count != 1 or redundant is None:
            return -1, b""
        return 2, struct.pack("<ii", *redundant)

    if algorithm == "zigzag_conversion":
        if (not 1 <= len(values) <= 1025
                or any(type(value) is not int for value in values)):
            return -1, b""
        rows, text = values[0], values[1:]
        if (not 1 <= rows <= 1024
                or any(not (65 <= value <= 90 or 97 <= value <= 122) for value in text)):
            return -1, b""
        if not text or rows == 1 or rows >= len(text):
            return len(text), bytes(text)
        cycle = 2 * (rows - 1)
        output = bytearray()
        for row in range(rows):
            index = row
            step = cycle if row == 0 or row + 1 == rows else cycle - 2 * row
            while index < len(text):
                output.append(text[index])
                index += step
                if row > 0 and row + 1 < rows:
                    step = cycle - step
        return len(output), bytes(output)

    if algorithm in {"longest_palindromic_substring", "longest_palindromic_substring_dp"}:
        if (not 1 <= len(values) <= 1000
                or any(type(value) is not int or
                       not (48 <= value <= 57 or 65 <= value <= 90 or 97 <= value <= 122)
                       for value in values)):
            return -1, b""
        length = len(values)
        palindrome = [[False] * length for _ in range(length)]
        best_start = 0
        best_length = 0
        for start in range(length - 1, -1, -1):
            for end in range(start, length):
                is_palindrome = (values[start] == values[end] and
                                 (end - start < 2 or palindrome[start + 1][end - 1]))
                palindrome[start][end] = is_palindrome
                candidate_length = end - start + 1
                better_tie = (start > best_start if algorithm == "longest_palindromic_substring_dp"
                              else start < best_start)
                if (is_palindrome and
                        (candidate_length > best_length or
                         (candidate_length == best_length and better_tie))):
                    best_start = start
                    best_length = candidate_length
        return best_length, bytes(values[best_start:best_start + best_length])

    if algorithm == "3sum":
        import struct
        from collections import Counter

        if (len(values) > 257
                or any(type(value) is not int or not -100_000 <= value <= 100_000
                       for value in values)):
            return -1, b""
        frequencies = Counter(values)
        distinct = sorted(frequencies)
        triplets = []
        for first_index, first in enumerate(distinct):
            for second in distinct[first_index:]:
                third = -first - second
                if third < second or third not in frequencies:
                    continue
                if first == second == third:
                    if frequencies[first] < 3:
                        continue
                elif first == second:
                    if frequencies[first] < 2:
                        continue
                elif second == third and frequencies[second] < 2:
                    continue
                triplets.append((first, second, third))
        output = b"".join(struct.pack("<iii", *triplet) for triplet in triplets)
        return len(triplets), output

    if algorithm == "rotate_array":
        import struct

        if (not 1 <= len(values) <= 1025
                or any(type(value) is not int for value in values)):
            return -1, b""
        rotations, *items = values
        if not 0 <= rotations <= 1024 or len(items) > 1024:
            return -1, b""
        if any(not -(2**31) <= value < 2**31 for value in items):
            return -1, b""
        shift = rotations % len(items) if items else 0
        rotated = items[-shift:] + items[:-shift] if shift else items[:]
        output = struct.pack("<" + "i" * len(rotated), *rotated) if rotated else b""
        return len(rotated), output

    if algorithm == "squares_of_a_sorted_array":
        import struct

        if (len(values) > MAX_SQUARED_ARRAY_INPUT_LENGTH
                or any(type(value) is not int or not -10000 <= value <= 10000
                       for value in values)
                or any(values[index - 1] > values[index] for index in range(1, len(values)))):
            return -1, b""
        squared = sorted(value * value for value in values)
        output = struct.pack("<" + "q" * len(squared), *squared) if squared else b""
        return len(squared), output

    if algorithm == "rotate_array_reversal":
        import struct

        if (not 1 <= len(values) <= 1025
                or any(type(value) is not int for value in values)):
            return -1, b""
        steps, *items = values
        if not -(2**31) <= steps < 2**31 or len(items) > 1024:
            return -1, b""
        if any(not -(2**31) <= value < 2**31 for value in items):
            return -1, b""
        shift = steps % len(items) if items else 0
        rotated = items[-shift:] + items[:-shift] if shift else items[:]
        output = struct.pack("<" + "i" * len(rotated), *rotated) if rotated else b""
        return len(rotated), output

    if algorithm == "swap_pairs":
        import struct

        if (len(values) > 1024
                or any(type(value) is not int or not -(2**31) <= value < 2**31 for value in values)):
            return -1, b""
        swapped = []
        for index in range(0, len(values), 2):
            if index + 1 < len(values):
                swapped.extend((values[index + 1], values[index]))
            else:
                swapped.append(values[index])
        output = struct.pack("<" + "i" * len(swapped), *swapped) if swapped else b""
        return len(swapped), output

    if algorithm == "remove_nth_node_from_end_of_list":
        import struct

        if (not 2 <= len(values) <= 1025
                or any(type(value) is not int or not -(2**31) <= value < 2**31
                       for value in values)):
            return -1, b""
        list_length = len(values) - 1
        position = values[0]
        if not 1 <= position <= list_length:
            return -1, b""
        removed_index = list_length - position + 1
        remaining = values[1:removed_index] + values[removed_index + 1:]
        output = struct.pack("<" + "i" * len(remaining), *remaining) if remaining else b""
        return len(remaining), output

    if algorithm == "caesar_cipher":
        if (not 1 <= len(values) <= MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int for value in values)
                or any(not 0 <= value <= 127 for value in values[:-1])):
            return -1, b""
        shift = values[-1] % 26
        output = bytearray(values[:-1])
        for index, value in enumerate(output):
            if ord("A") <= value <= ord("Z"):
                output[index] = ord("A") + (value - ord("A") + shift) % 26
            elif ord("a") <= value <= ord("z"):
                output[index] = ord("a") + (value - ord("a") + shift) % 26
        return len(output), bytes(output)

    if algorithm == "gale_shapley":
        if (not 1 <= len(values) <= MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= 5):
            return -2, b""
        count = values[0]
        if len(values) != 1 + 2 * count * count:
            return -2, b""
        proposer_preferences = [values[1 + proposer * count:1 + (proposer + 1) * count]
                                for proposer in range(count)]
        accepter_offset = 1 + count * count
        accepter_preferences = [values[accepter_offset + accepter * count:
                                        accepter_offset + (accepter + 1) * count]
                                for accepter in range(count)]
        expected_ids = set(range(count))
        if any(set(preferences) != expected_ids for preferences in
               proposer_preferences + accepter_preferences):
            return -2, b""
        accepter_ranks = [{proposer: rank for rank, proposer in enumerate(preferences)}
                          for preferences in accepter_preferences]
        matched_by_accepter = [-1] * count
        matched_by_proposer = [-1] * count
        next_choice = [0] * count
        while True:
            proposer = next((index for index, partner in enumerate(matched_by_proposer)
                             if partner == -1), count)
            if proposer == count:
                break
            accepter = proposer_preferences[proposer][next_choice[proposer]]
            next_choice[proposer] += 1
            current = matched_by_accepter[accepter]
            if current == -1 or accepter_ranks[accepter][proposer] < accepter_ranks[accepter][current]:
                if current != -1:
                    matched_by_proposer[current] = -1
                matched_by_accepter[accepter] = proposer
                matched_by_proposer[proposer] = accepter
        return count, bytes(matched_by_proposer)

    if algorithm in {"rot13", "theoretical_rot13"}:
        if (len(values) > MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int or not 1 <= value <= 127 for value in values)):
            return -1, b""
        output = bytearray(values)
        for index, value in enumerate(output):
            if algorithm == "rot13" and ord("A") <= value <= ord("Z"):
                output[index] = ord("A") + (value - ord("A") + 13) % 26
            elif ord("a") <= value <= ord("z"):
                output[index] = ord("a") + (value - ord("a") + 13) % 26
        return len(output), bytes(output)

    if algorithm == "tower_of_hanoi":
        if (len(values) != 4 or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= 12
                or any(not 0 <= peg <= 2 for peg in values[1:])
                or len(set(values[1:])) != 3):
            return -1, b""
        disks, source, destination, auxiliary = values
        moves = bytearray()

        def emit(count: int, origin: int, target: int, spare: int) -> None:
            if count == 0:
                return
            emit(count - 1, origin, spare, target)
            moves.extend((origin, target))
            emit(count - 1, spare, target, origin)

        emit(disks, source, destination, auxiliary)
        return len(moves) // 2, bytes(moves)

    if algorithm in {"breadth_first_search", "depth_first_search"}:
        if (not 2 <= len(values) <= MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= 64
                or (len(values) - 2) % 2 != 0):
            return -2, b""
        vertices, start = values[:2]
        if vertices == 0:
            return (0, b"") if start == -1 and len(values) == 2 else (-2, b"")
        if not 0 <= start < vertices:
            return -2, b""
        adjacency = [set() for _ in range(vertices)]
        for offset in range(2, len(values), 2):
            origin, destination = values[offset:offset + 2]
            if not 0 <= origin < vertices or not 0 <= destination < vertices:
                return -2, b""
            adjacency[origin].add(destination)
        order = []
        visited = {start}
        if algorithm == "breadth_first_search":
            queue = [start]
            head = 0
            while head < len(queue):
                origin = queue[head]
                head += 1
                order.append(origin)
                for destination in sorted(adjacency[origin]):
                    if destination not in visited:
                        visited.add(destination)
                        queue.append(destination)
        else:
            order.append(start)
            frames = [(start, iter(sorted(adjacency[start])))]
            while frames:
                origin, neighbors = frames[-1]
                destination = next(neighbors, None)
                if destination is None:
                    frames.pop()
                elif destination not in visited:
                    visited.add(destination)
                    order.append(destination)
                    frames.append((destination, iter(sorted(adjacency[destination]))))
        return len(order), bytes(order)

    if algorithm == "topological_sort":
        if (not 1 <= len(values) <= MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= 64
                or (len(values) - 1) % 2 != 0):
            return -2, b""
        vertices = values[0]
        adjacency = [set() for _ in range(vertices)]
        indegree = [0] * vertices
        for offset in range(1, len(values), 2):
            origin, destination = values[offset:offset + 2]
            if not 0 <= origin < vertices or not 0 <= destination < vertices:
                return -2, b""
            if destination not in adjacency[origin]:
                adjacency[origin].add(destination)
                indegree[destination] += 1
        queue = [vertex for vertex, degree in enumerate(indegree) if degree == 0]
        order = []
        head = 0
        while head < len(queue):
            origin = queue[head]
            head += 1
            order.append(origin)
            for destination in range(vertices):
                if destination in adjacency[origin]:
                    indegree[destination] -= 1
                    if indegree[destination] == 0:
                        queue.append(destination)
        if len(order) != vertices:
            return -1, b""
        return vertices, bytes(order)

    if algorithm == "letter_combinations_of_phone_number":
        if len(values) == 0:
            return 0, b""
        if len(values) > 6 or any(value not in KEYPAD for value in values):
            return -1, b""
        rows = [b""]
        for value in values:
            rows = [prefix + bytes((letter,)) for prefix in rows for letter in KEYPAD[value]]
        output = b"".join(rows)
        return len(rows), output

    if algorithm in {"decimal_to_any_base", "decimal_to_any_using_stack"}:
        if (len(values) != 2 or any(type(value) is not int for value in values)):
            return -1, b""
        number, base = values
        maximum_base = 16 if algorithm == "decimal_to_any_using_stack" else 36
        if number < 0 or not 2 <= base <= maximum_base:
            return -1, b""
        alphabet = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        digits = bytearray()
        while number:
            number, digit = divmod(number, base)
            digits.append(alphabet[digit])
        if not digits:
            digits.append(ord("0"))
        digits.reverse()
        return len(digits), bytes(digits)

    if algorithm == "any_base_to_any_base":
        if (len(values) < 3 or len(values) > 65
                or any(type(value) is not int for value in values)):
            return -1, b""
        source_base, target_base = values[:2]
        if not 2 <= source_base <= 36 or not 2 <= target_base <= 36:
            return -1, b""
        number = 0
        for digit in values[2:]:
            if not 0 <= digit < source_base:
                return -1, b""
            number = number * source_base + digit
            if number > 2**63 - 1:
                return -1, b""
        alphabet = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        digits = bytearray()
        while number:
            number, digit = divmod(number, target_base)
            digits.append(alphabet[digit])
        if not digits:
            digits.append(ord("0"))
        digits.reverse()
        return len(digits), bytes(digits)

    if algorithm == "base_neg2_conversion":
        if (len(values) != 1 or type(values[0]) is not int
                or not -(2**63) <= values[0] < 2**63):
            return -1, b""
        number = values[0]
        digits = bytearray()
        while number:
            digit = number % 2
            digits.append(ord("0") + digit)
            number = (number - digit) // -2
        if not digits:
            digits.append(ord("0"))
        digits.reverse()
        return len(digits), bytes(digits)

    if algorithm == "base16":
        if (not 1 <= len(values) <= 65
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        if mode == 0:
            if any(not 0 <= value <= 255 for value in payload):
                return -1, b""
            encoded = bytes(payload).hex().upper().encode("ascii")
            return len(encoded), encoded
        if mode == 1:
            if (len(payload) % 2 != 0
                    or any(value not in b"0123456789ABCDEF" for value in payload)):
                return -1, b""
            encoded = bytes(payload).decode("ascii")
            decoded = bytes.fromhex(encoded)
            return len(decoded), decoded
        return -1, b""

    if algorithm == "base32":
        if (not 1 <= len(values) <= 66
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        alphabet = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        if mode == 0:
            if any(not 0 <= value <= 255 for value in payload):
                return -1, b""
            source = bytes(payload)
            if not source:
                return 0, b""
            output = bytearray()
            for offset in range(0, len(source), 5):
                block = source[offset:offset + 5]
                bits = len(block) * 8
                for symbol in range((bits + 4) // 5):
                    value = 0
                    for bit in range(symbol * 5, symbol * 5 + 5):
                        value <<= 1
                        if bit < bits:
                            value |= (block[bit // 8] >> (7 - bit % 8)) & 1
                    output.append(alphabet[value])
                while len(output) % 8:
                    output.append(ord("="))
            return len(output), bytes(output)
        if mode != 1:
            return -1, b""

        encoded = payload
        first_padding = next((index for index, value in enumerate(encoded) if value == ord("=")), len(encoded))
        content_length = first_padding
        padding_length = len(encoded) - content_length
        content = encoded[:content_length]
        if any(value not in alphabet for value in content) or any(value != ord("=") for value in encoded[content_length:]):
            return -1, b""
        remainder = content_length % 8
        expected_padding = {0: 0, 2: 6, 4: 4, 5: 3, 7: 1}.get(remainder)
        if expected_padding is None:
            return -1, b""
        if padding_length and (len(encoded) % 8 != 0 or padding_length != expected_padding):
            return -1, b""
        if content_length and remainder:
            final_value = alphabet.index(content[-1])
            unused_bits = {2: 2, 4: 4, 5: 1, 7: 3}[remainder]
            if final_value & ((1 << unused_bits) - 1):
                return -1, b""
        output_length = content_length * 5 // 8
        output = bytearray(output_length)
        for bit in range(output_length * 8):
            symbol_value = alphabet.index(content[bit // 5])
            output[bit // 8] |= ((symbol_value >> (4 - bit % 5)) & 1) << (7 - bit % 8)
        return output_length, bytes(output)

    if algorithm == "base64":
        if (not 1 <= len(values) <= 66
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        alphabet = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        if mode == 0:
            if any(not 0 <= value <= 255 for value in payload):
                return -1, b""
            source = bytes(payload)
            if not source:
                return 0, b""
            output = bytearray()
            symbols = (len(source) * 8 + 5) // 6
            output_length = ((len(source) + 2) // 3) * 4
            for symbol in range(output_length):
                if symbol >= symbols:
                    output.append(ord("="))
                    continue
                value = 0
                for bit in range(symbol * 6, symbol * 6 + 6):
                    value <<= 1
                    if bit < len(source) * 8:
                        value |= (source[bit // 8] >> (7 - bit % 8)) & 1
                output.append(alphabet[value])
            return output_length, bytes(output)
        if mode != 1:
            return -1, b""

        encoded = payload
        content_length = next((index for index, value in enumerate(encoded) if value == ord("=")), len(encoded))
        padding_length = len(encoded) - content_length
        content = encoded[:content_length]
        if any(value not in alphabet for value in content) or any(value != ord("=") for value in encoded[content_length:]):
            return -1, b""
        remainder = content_length % 4
        expected_padding = {0: 0, 2: 2, 3: 1}.get(remainder)
        if expected_padding is None:
            return -1, b""
        if padding_length and (len(encoded) % 4 != 0 or padding_length != expected_padding):
            return -1, b""
        if content_length and remainder:
            final_value = alphabet.index(content[-1])
            unused_bits = 4 if remainder == 2 else 2
            if final_value & ((1 << unused_bits) - 1):
                return -1, b""
        output_length = content_length * 6 // 8
        output = bytearray(output_length)
        for bit in range(output_length * 8):
            symbol_value = alphabet.index(content[bit // 6])
            output[bit // 8] |= ((symbol_value >> (5 - bit % 6)) & 1) << (7 - bit % 8)
        return output_length, bytes(output)

    if algorithm in {"binary_to_octal", "binary_to_hexadecimal"}:
        if (not 1 <= len(values) <= 63
                or any(type(value) is not int or value not in (0, 1) for value in values)):
            return -1, b""
        number = 0
        for bit in values:
            number = number * 2 + bit
        encoded = format(number, "o" if algorithm == "binary_to_octal" else "x").encode("ascii")
        return len(encoded), encoded

    if algorithm in {"octal_to_binary", "octal_to_hexadecimal"}:
        if (not 1 <= len(values) <= 21
                or any(type(value) is not int or value not in range(8) for value in values)):
            return -1, b""
        number = 0
        for digit in values:
            number = number * 8 + digit
        encoded = format(number, "b" if algorithm == "octal_to_binary" else "x").encode("ascii")
        return len(encoded), encoded

    if algorithm in {"hexadecimal_to_binary", "hexadecimal_to_octal"}:
        if (not 1 <= len(values) <= 16
                or any(type(value) is not int or value not in range(16) for value in values)):
            return -1, b""
        number = 0
        for digit in values:
            number = number * 16 + digit
        if number > 2**63 - 1:
            return -1, b""
        encoded = format(number, "b" if algorithm == "hexadecimal_to_binary" else "o").encode("ascii")
        return len(encoded), encoded

    raise ValueError(f"no byte-output oracle for {algorithm}")


def fnv1a(data: bytes) -> int:
    result = 14695981039346656037
    for value in data:
        result = ((result ^ value) * 1099511628211) & ((1 << 64) - 1)
    return result


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
    if manifest.get("family") != "i64_array_bytes_output":
        parser.error("build manifest must declare the i64_array_bytes_output ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["i64_array_bytes_output_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/i64_array_bytes_output_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
        parser.error("workload does not match the built byte-output algorithm")
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
        values = case.get("input_values")
        max_input_length = (MAX_MATRIX_INPUT_LENGTH if algorithm == "ones_minus_zeros" else
                            MAX_ACCOUNT_MERGE_INPUT_LENGTH if algorithm == "account_merge" else
                            MAX_A_STAR_INPUT_LENGTH if algorithm == "a_star_search" else
                            MAX_AFFINE_CIPHER_INPUT_LENGTH if algorithm == "affine_cipher" else
                            MAX_SQUARE_STREAK_INPUT_LENGTH if algorithm == "longest_square_streak" else
                            MAX_SQUARED_ARRAY_INPUT_LENGTH if algorithm == "squares_of_a_sorted_array" else
                            MAX_SORT_ARRAY_BY_PARITY_INPUT_LENGTH if algorithm == "sort_array_by_parity" else
                            MAX_FIND_DUPLICATES_INPUT_LENGTH + 1 if algorithm == "find_all_duplicates_in_array" else
                            MAX_REDUNDANT_CONNECTION_INPUT_LENGTH + 2 if algorithm == "redundant_connection" else
                            MAX_INPUT_LENGTH)
        if (not isinstance(values, list) or len(values) > max_input_length
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            raise ValueError(f"invalid signed 64-bit digit array in {case['id']}")
        if case.get("input_length") not in (None, len(values)):
            raise ValueError(f"declared input length differs for {case['id']}")
        expected_count, expected = expected_output(values, algorithm)
        if case.get("expected_result") != expected_count:
            raise ValueError(f"workload oracle mismatch for {case['id']}")
        output_hex = expected.hex() if expected else "-"
        output_capacity = case.get("workspace_bytes", len(expected))
        if (type(output_capacity) is not int or output_capacity < len(expected)
                or output_capacity > MAX_OUTPUT_CAPACITY):
            raise ValueError(f"invalid output capacity in {case['id']}")
        command = [str(executable), "--stdin", str(samples), str(warmups), str(repetitions)]
        runner_input = (f"{len(values)} {expected_count} {len(expected)} {output_capacity} "
                        + " ".join(map(str, values)) + " " + output_hex + "\n")
        completed = subprocess.run(command, input=runner_input, capture_output=True,
                                   text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"byte-output runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        expected_checksum = (fnv1a(expected) * repetitions * samples) & ((1 << 64) - 1)
        if (raw["observed_result"] != expected_count or len(raw["samples_ns"]) != samples
                or raw["result_checksum"] != expected_checksum):
            raise ValueError(f"byte-output runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(values), "input_values": values,
                                     "case": case["id"], "target": None,
                                     "expected_result": expected_count},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "i64_array_bytes_output_call",
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
