#!/usr/bin/env python3
"""Record a byte-output benchmark over a signed 64-bit input array."""

from __future__ import annotations

import argparse
from collections import deque
import datetime as dt
from functools import lru_cache
from fractions import Fraction
import heapq
import hashlib
from itertools import permutations
import json
import math
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
MAX_WAVE_SORT_INPUT_LENGTH = 4096
MAX_FIND_DUPLICATES_INPUT_LENGTH = 100000
MAX_REDUNDANT_CONNECTION_INPUT_LENGTH = 2000
MAX_A_STAR_INPUT_LENGTH = 4 + 256 + 2 * 4096
MAX_NAIVE_SHUFFLER_INPUT_LENGTH = 2 + 256
MAX_ACCOUNT_MERGE_INPUT_LENGTH = 100002
MAX_BURROWS_WHEELER_LENGTH = 256
MAX_BFS_QUEUE_INPUT_LENGTH = 4 + 2 * 2046
MAX_ZERO_ONE_BFS_INPUT_LENGTH = 3 + 3 * 1024
MAX_ARTICULATION_POINTS_INPUT_LENGTH = 2 + 2 * 2047
MAX_BRIDGES_INPUT_LENGTH = 2 + 2 * 2047
MAX_SCC_INPUT_LENGTH = 2 + 2 * 2047
MAX_BACONIAN_PAYLOAD_LENGTH = 1024
MAX_VERNAM_TEXT_LENGTH = 1024
MAX_VERNAM_KEY_LENGTH = 1024
MAX_AUTOKEY_TEXT_LENGTH = 1024
MAX_AUTOKEY_KEY_LENGTH = 1024
MAX_BEAUFORT_TEXT_LENGTH = 1024
MAX_BEAUFORT_KEY_LENGTH = 1024
MAX_FRACTIONATED_MORSE_TEXT_LENGTH = 256
MAX_FRACTIONATED_MORSE_KEY_LENGTH = 64
MAX_PORTA_TEXT_LENGTH = 1024
MAX_PORTA_KEY_LENGTH = 64
MAX_GRONSFELD_TEXT_LENGTH = 256
MAX_GRONSFELD_KEY_LENGTH = 64
MAX_REVERSE_COMPLEMENT_LENGTH = 1000
MAX_WORD_COUNT_JULIA_LENGTH = 1000
MAX_WORD_SEARCH_GENERATOR_DIMENSION = 32
MAX_WORD_SEARCH_GENERATOR_WORDS = 96
MAX_WORD_SEARCH_GENERATOR_WORD_LENGTH = 32
WORD_SEARCH_GENERATOR_RNG_MODULUS = 2147483647
KEYPAD = {2: b"abc", 3: b"def", 4: b"ghi", 5: b"jkl", 6: b"mno",
          7: b"pqrs", 8: b"tuv", 9: b"wxyz"}

BACONIAN_STANDARD_CODES = tuple(
    "".join("B" if (value >> bit) & 1 else "A" for bit in range(4, -1, -1))
    for value in range(26)
)
BACONIAN_PYTHON_CODES = dict(zip(
    "abcdefghijklmnopqrstuvwxyz",
    ("AAAAA", "AAAAB", "AAABA", "AAABB", "AABAA", "AABAB", "AABBA", "AABBB",
     "ABAAA", "BBBAA", "ABAAB", "ABABA", "ABABB", "ABBAA", "ABBAB", "ABBBA",
     "ABBBB", "BAAAA", "BAAAB", "BAABA", "BAABB", "BBBAB", "BABAA", "BABAB",
     "BABBA", "BABBB"),
))


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

FRACTIONATED_MORSE_CODES = (
    b".-", b"-...", b"-.-.", b"-..", b".", b"..-.", b"--.", b"....", b"..", b".---",
    b"-.-", b".-..", b"--", b"-.", b"---", b".--.", b"--.-", b".-.", b"...", b"-",
    b"..-", b"...-", b".--", b"-..-", b"-.--", b"--..",
)
FRACTIONATED_MORSE_TRIGRAMS = tuple(
    bytes((first, second, third))
    for first in b".-x" for second in b".-x" for third in b".-x"
)
FRACTIONATED_MORSE_REVERSE = {code: 65 + index for index, code in enumerate(FRACTIONATED_MORSE_CODES)}

PORTA_SECOND_ROWS = (
    b"NOPQRSTUVWXYZ", b"ZNOPQRSTUVWXY", b"YZNOPQRSTUVWX", b"XYZNOPQRSTUVW",
    b"WXYZNOPQRSTUV", b"VWXYZNOPQRSTU", b"UVWXYZNOPQRST", b"TUVWXYZNOPQRS",
    b"STUVWXYZNOPQR", b"RSTUVWXYZNOPQ", b"QRSTUVWXYZNOP", b"PQRSTUVWXYZNO",
    b"OPQRSTUVWXYZN",
)


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


def lowest_common_ancestor_batch_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 4 or len(values) > 2562
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    node_count, root, edge_count, query_count = values[:4]
    if (not 1 <= node_count <= 256 or not 0 <= root < node_count
            or edge_count != node_count - 1 or not 0 <= query_count <= 1024
            or len(values) != 4 + 2 * edge_count + 2 * query_count):
        return -1, b""

    adjacency: list[list[int]] = [[] for _ in range(node_count)]
    edge_end = 4 + 2 * edge_count
    for offset in range(4, edge_end, 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < node_count or not 0 <= right < node_count or left == right:
            return -1, b""
        adjacency[left].append(right)
        adjacency[right].append(left)
    queries = list(zip(values[edge_end::2], values[edge_end + 1::2]))
    if any(not 0 <= node < node_count for query in queries for node in query):
        return -1, b""

    parent = [-2] * node_count
    depth = [0] * node_count
    parent[root] = -1
    stack = [root]
    reached = 0
    while stack:
        node = stack.pop()
        reached += 1
        for neighbor in adjacency[node]:
            if neighbor == parent[node]:
                continue
            if parent[neighbor] != -2:
                return -1, b""
            parent[neighbor] = node
            depth[neighbor] = depth[node] + 1
            stack.append(neighbor)
    if reached != node_count:
        return -1, b""

    answers = bytearray()
    for left, right in queries:
        while depth[left] > depth[right]:
            left = parent[left]
        while depth[right] > depth[left]:
            right = parent[right]
        while left != right:
            left = parent[left]
            right = parent[right]
        answers.append(left)
    return query_count, bytes(answers)


def bfs_queue_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 4 or len(values) > MAX_BFS_QUEUE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    vertex_count, source, target, edge_count = values[:4]
    if (not 1 <= vertex_count <= 64 or not 0 <= source < vertex_count
            or not 0 <= target < vertex_count or not 0 <= edge_count <= 2046
            or len(values) != 4 + 2 * edge_count):
        return -1, b""

    adjacency: list[set[int]] = [set() for _ in range(vertex_count)]
    for offset in range(4, len(values), 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < vertex_count or not 0 <= right < vertex_count:
            return -1, b""
        adjacency[left].add(right)
        adjacency[right].add(left)

    predecessor: list[int | None] = [None] * vertex_count
    predecessor[source] = source
    queue = [source]
    head = 0
    while head < len(queue) and predecessor[target] is None:
        current = queue[head]
        head += 1
        for neighbor in sorted(adjacency[current]):
            if predecessor[neighbor] is not None:
                continue
            predecessor[neighbor] = current
            if neighbor == target:
                break
            queue.append(neighbor)
    if predecessor[target] is None:
        output = b"\x00"
        return len(output), output

    reverse_path = []
    current = target
    while True:
        reverse_path.append(current)
        if current == source:
            break
        current = predecessor[current]
    output = bytes([1, *reverse_path])
    return len(output), output


def zero_one_bfs_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 3 or len(values) > MAX_ZERO_ONE_BFS_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    vertex_count, source, edge_count = values[:3]
    if (not 1 <= vertex_count <= 64 or not 0 <= source < vertex_count
            or not 0 <= edge_count <= 1024 or len(values) != 3 + 3 * edge_count):
        return -1, b""

    zero_adjacency: list[set[int]] = [set() for _ in range(vertex_count)]
    one_adjacency: list[set[int]] = [set() for _ in range(vertex_count)]
    for offset in range(3, len(values), 3):
        origin, destination, weight = values[offset:offset + 3]
        if not 0 <= origin < vertex_count or not 0 <= destination < vertex_count or weight not in (0, 1):
            return -1, b""
        (zero_adjacency if weight == 0 else one_adjacency)[origin].add(destination)

    distances: list[int | None] = [None] * vertex_count
    distances[source] = 0
    queue = deque([source])
    while queue:
        origin = queue.popleft()
        origin_distance = distances[origin]
        if origin_distance is None:
            continue
        for destination in sorted(zero_adjacency[origin]):
            if distances[destination] is None or origin_distance < distances[destination]:
                distances[destination] = origin_distance
                queue.appendleft(destination)
        for destination in sorted(one_adjacency[origin]):
            candidate = origin_distance + 1
            if distances[destination] is None or candidate < distances[destination]:
                distances[destination] = candidate
                queue.append(destination)
    return vertex_count, bytes(255 if distance is None else distance for distance in distances)


def articulation_points_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_ARTICULATION_POINTS_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    vertex_count, edge_count = values[:2]
    if (not 0 <= vertex_count <= 64 or not 0 <= edge_count <= 2047
            or len(values) != 2 + 2 * edge_count):
        return -1, b""

    adjacency: list[set[int]] = [set() for _ in range(vertex_count)]
    for offset in range(2, len(values), 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < vertex_count or not 0 <= right < vertex_count:
            return -1, b""
        adjacency[left].add(right)
        adjacency[right].add(left)

    discovery = [-1] * vertex_count
    low = [0] * vertex_count
    parent = [-1] * vertex_count
    is_articulation = [False] * vertex_count
    time = 0

    def visit(node: int) -> None:
        nonlocal time
        discovery[node] = low[node] = time
        time += 1
        child_count = 0
        for neighbor in sorted(adjacency[node]):
            if discovery[neighbor] == -1:
                parent[neighbor] = node
                child_count += 1
                visit(neighbor)
                low[node] = min(low[node], low[neighbor])
                if parent[node] == -1 and child_count > 1:
                    is_articulation[node] = True
                elif parent[node] != -1 and low[neighbor] >= discovery[node]:
                    is_articulation[node] = True
            elif neighbor != parent[node]:
                low[node] = min(low[node], discovery[neighbor])

    for vertex in range(vertex_count):
        if discovery[vertex] == -1:
            visit(vertex)
    output = bytes(vertex for vertex, is_cut in enumerate(is_articulation) if is_cut)
    return len(output), output


def bridges_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_BRIDGES_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    vertex_count, edge_count = values[:2]
    if (not 0 <= vertex_count <= 64 or not 0 <= edge_count <= 2047
            or len(values) != 2 + 2 * edge_count):
        return -1, b""

    adjacency: list[set[int]] = [set() for _ in range(vertex_count)]
    for offset in range(2, len(values), 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < vertex_count or not 0 <= right < vertex_count:
            return -1, b""
        adjacency[left].add(right)
        adjacency[right].add(left)

    discovery = [-1] * vertex_count
    low = [0] * vertex_count
    parent = [-1] * vertex_count
    bridge_edges: list[tuple[int, int]] = []
    time = 0

    def visit(node: int) -> None:
        nonlocal time
        discovery[node] = low[node] = time
        time += 1
        for neighbor in sorted(adjacency[node]):
            if discovery[neighbor] == -1:
                parent[neighbor] = node
                visit(neighbor)
                low[node] = min(low[node], low[neighbor])
                if low[neighbor] > discovery[node]:
                    bridge_edges.append((min(node, neighbor), max(node, neighbor)))
            elif neighbor != parent[node]:
                low[node] = min(low[node], discovery[neighbor])

    for vertex in range(vertex_count):
        if discovery[vertex] == -1:
            visit(vertex)
    output = bytes(value for edge in sorted(bridge_edges) for value in edge)
    return len(output), output


def _scc_input_graph(values: list[int]) -> list[list[int]] | None:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_SCC_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return None
    vertex_count, edge_count = values[:2]
    if (not 0 <= vertex_count <= 40 or not 0 <= edge_count <= 2047
            or len(values) != 2 + 2 * edge_count):
        return None
    adjacency: list[set[int]] = [set() for _ in range(vertex_count)]
    for offset in range(2, len(values), 2):
        source, target = values[offset:offset + 2]
        if not 0 <= source < vertex_count or not 0 <= target < vertex_count:
            return None
        adjacency[source].add(target)
    return [sorted(neighbors) for neighbors in adjacency]


def _encode_scc_components(components: list[list[int]]) -> tuple[int, bytes]:
    ordered = sorted((sorted(component) for component in components), key=lambda component: tuple(component))
    output = bytearray([len(ordered)])
    for component in ordered:
        output.append(len(component))
        output.extend(component)
    return len(output), bytes(output)


def kosaraju_output(values: list[int]) -> tuple[int, bytes]:
    adjacency = _scc_input_graph(values)
    if adjacency is None:
        return -1, b""
    vertex_count = len(adjacency)
    transpose: list[list[int]] = [[] for _ in range(vertex_count)]
    for source, neighbors in enumerate(adjacency):
        for target in neighbors:
            transpose[target].append(source)
    visited = [False] * vertex_count
    order: list[int] = []

    def fill_order(vertex: int) -> None:
        visited[vertex] = True
        for neighbor in adjacency[vertex]:
            if not visited[neighbor]:
                fill_order(neighbor)
        order.append(vertex)

    for vertex in range(vertex_count):
        if not visited[vertex]:
            fill_order(vertex)
    visited = [False] * vertex_count
    components: list[list[int]] = []

    def collect(vertex: int, component: list[int]) -> None:
        visited[vertex] = True
        component.append(vertex)
        for neighbor in transpose[vertex]:
            if not visited[neighbor]:
                collect(neighbor, component)

    for vertex in reversed(order):
        if not visited[vertex]:
            component: list[int] = []
            collect(vertex, component)
            components.append(component)
    return _encode_scc_components(components)


def tarjan_scc_output(values: list[int]) -> tuple[int, bytes]:
    adjacency = _scc_input_graph(values)
    if adjacency is None:
        return -1, b""
    vertex_count = len(adjacency)
    discovery = [-1] * vertex_count
    low = [0] * vertex_count
    on_stack = [False] * vertex_count
    stack: list[int] = []
    components: list[list[int]] = []
    time = 0

    def visit(vertex: int) -> None:
        nonlocal time
        discovery[vertex] = low[vertex] = time
        time += 1
        stack.append(vertex)
        on_stack[vertex] = True
        for neighbor in adjacency[vertex]:
            if discovery[neighbor] == -1:
                visit(neighbor)
                low[vertex] = min(low[vertex], low[neighbor])
            elif on_stack[neighbor]:
                low[vertex] = min(low[vertex], discovery[neighbor])
        if low[vertex] == discovery[vertex]:
            component = []
            while True:
                member = stack.pop()
                on_stack[member] = False
                component.append(member)
                if member == vertex:
                    break
            components.append(component)

    for vertex in range(vertex_count):
        if discovery[vertex] == -1:
            visit(vertex)
    return _encode_scc_components(components)


def word_search_generator_output(values: list[int]) -> tuple[int, bytes]:
    """Deterministically place words on a board using the documented 8-way search."""
    if (not isinstance(values, list) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    width, height, seed, word_count = values[:4]
    if (not 1 <= width <= MAX_WORD_SEARCH_GENERATOR_DIMENSION
            or not 1 <= height <= MAX_WORD_SEARCH_GENERATOR_DIMENSION
            or not 1 <= seed < WORD_SEARCH_GENERATOR_RNG_MODULUS
            or not 0 <= word_count <= MAX_WORD_SEARCH_GENERATOR_WORDS):
        return -1, b""
    words = []
    position = 4
    for _ in range(word_count):
        if position >= len(values):
            return -1, b""
        word_length = values[position]
        position += 1
        if (not 1 <= word_length <= MAX_WORD_SEARCH_GENERATOR_WORD_LENGTH
                or word_length > len(values) - position):
            return -1, b""
        word = values[position:position + word_length]
        if any(not (65 <= letter <= 90 or 97 <= letter <= 122) for letter in word):
            return -1, b""
        words.append(bytes(word))
        position += word_length
    if position != len(values):
        return -1, b""

    state = seed

    def next_random() -> int:
        nonlocal state
        state = state * 48271 % WORD_SEARCH_GENERATOR_RNG_MODULUS
        return state

    def shuffle(indices: list[int]) -> None:
        for index in range(len(indices) - 1, 0, -1):
            other = next_random() % (index + 1)
            indices[index], indices[other] = indices[other], indices[index]

    directions = ((-1, 0), (-1, 1), (0, 1), (1, 1),
                  (1, 0), (1, -1), (0, -1), (-1, -1))
    board = bytearray(width * height)
    for word in words:
        rows = list(range(height))
        columns = list(range(width))
        shuffle(rows)
        shuffle(columns)
        row_delta, column_delta = directions[next_random() % len(directions)]
        placed = False
        for row in rows:
            for column in columns:
                end_row = row + (len(word) - 1) * row_delta
                end_column = column + (len(word) - 1) * column_delta
                if not (0 <= end_row < height and 0 <= end_column < width):
                    continue
                positions = [
                    (row + offset * row_delta) * width + column + offset * column_delta
                    for offset in range(len(word))
                ]
                if any(board[cell] != 0 for cell in positions):
                    continue
                for cell, letter in zip(positions, word):
                    board[cell] = letter
                placed = True
                break
            if placed:
                break
    return len(board), bytes(board)


def expected_output(values: list[int], algorithm: str = "letter_combinations_of_phone_number") -> tuple[int, bytes]:
    if algorithm == "ddaline":
        if (not isinstance(values, list) or len(values) != 4
                or any(type(value) is not int or not -128 <= value <= 128 for value in values)):
            return -1, b""
        x0, y0, x1, y1 = values
        dx, dy = x1 - x0, y1 - y0
        steps = max(abs(dx), abs(dy))
        if steps == 0:
            return 16, struct.pack("<qq", x0, y0)
        x_increment, y_increment = dx / steps, dy / steps
        x, y = float(x0), float(y0)
        output = bytearray()
        for _ in range(steps + 1):
            output.extend(struct.pack("<qq", math.floor(x + 0.5), math.floor(y + 0.5)))
            x += x_increment
            y += y_increment
        return len(output), bytes(output)

    if algorithm == "count_distinct_elements_in_window":
        if (not isinstance(values, list) or len(values) < 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        window_count, window_size = values[:2]
        window_values = values[2:]
        if (not 1 <= window_count <= 256 or not 1 <= window_size <= window_count
                or len(window_values) != window_count
                or any(not -(2**31) <= value < 2**31 for value in window_values)):
            return -1, b""
        counts = [len(set(window_values[start:start + window_size]))
                  for start in range(window_count - window_size + 1)]
        encoded = b"".join(struct.pack("<q", count) for count in counts)
        return len(encoded), encoded

    if algorithm == "association":
        if (not isinstance(values, list) or len(values) < 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        transaction_count, item_count = values[:2]
        transactions = values[2:]
        if (not 1 <= transaction_count <= 64 or not 1 <= item_count <= 11
                or len(transactions) != transaction_count
                or any(not 0 <= mask < (1 << item_count) for mask in transactions)):
            return -1, b""
        frequent_itemsets = []
        for cardinality in range(1, item_count + 1):
            for itemset_mask in range(1, 1 << item_count):
                if itemset_mask.bit_count() != cardinality:
                    continue
                support_count = sum((transaction & itemset_mask) == itemset_mask
                                    for transaction in transactions)
                if support_count >= 1:
                    frequent_itemsets.append((itemset_mask, support_count))
        encoded = b"".join(struct.pack("<qq", itemset_mask, support_count)
                           for itemset_mask, support_count in frequent_itemsets)
        return len(encoded), encoded

    if algorithm == "quadratic_roots":
        if (not isinstance(values, list) or len(values) != 3
                or any(type(value) is not int or not -1_000_000 <= value <= 1_000_000
                       for value in values)):
            return -1, b""
        a, b, c = values
        if a == 0:
            return -1, b""
        discriminant = b * b - 4 * a * c
        if discriminant < 0:
            roots = ()
        elif discriminant == 0:
            roots = (-b / (2.0 * a),)
        else:
            root = math.sqrt(discriminant)
            denominator = 2.0 * a
            roots = ((-b + root) / denominator, (-b - root) / denominator)
        return len(roots), b"".join(struct.pack("<d", value) for value in roots)

    if algorithm == "npv_sensitivity":
        if (not isinstance(values, list) or len(values) < 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        cash_flow_count, rate_count = values[:2]
        if (not 0 <= cash_flow_count <= 64 or not 0 <= rate_count <= 32
                or len(values) != 2 + cash_flow_count + rate_count):
            return -1, b""
        cash_flows = values[2:2 + cash_flow_count]
        rate_basis_points = values[2 + cash_flow_count:]
        if (any(not -1_000_000 <= cash_flow <= 1_000_000 for cash_flow in cash_flows)
                or any(not 0 <= basis_points <= 1_000 for basis_points in rate_basis_points)):
            return -1, b""
        results = []
        for basis_points in rate_basis_points:
            rate = basis_points / 10_000.0
            result = 0.0
            for period, cash_flow in enumerate(cash_flows):
                result += cash_flow / math.pow(1.0 + rate, period)
            results.append(result)
        encoded = b"".join(struct.pack("<d", value) for value in results)
        return len(encoded), encoded

    if algorithm == "arithmetic_decoding":
        if (not isinstance(values, list) or len(values) < 5 or len(values) > 27
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count, alphabet_size, code = values[:3]
        if (not 1 <= count <= 12 or not 1 <= alphabet_size <= count
                or len(values) != 3 + 2 * alphabet_size):
            return -1, b""
        model = []
        total = 0
        previous_symbol = -1
        cumulative = 0
        for index in range(alphabet_size):
            symbol, frequency = values[3 + 2 * index:5 + 2 * index]
            if (not 0 <= symbol <= 255 or symbol <= previous_symbol
                    or not 1 <= frequency <= count):
                return -1, b""
            model.append((symbol, cumulative, cumulative + frequency))
            previous_symbol = symbol
            cumulative += frequency
            total += frequency
        denominator = count ** count
        if total != count or not 0 <= code < denominator:
            return -1, b""
        encoded_value = Fraction(code, denominator)
        low, high = Fraction(0), Fraction(1)
        decoded = bytearray()
        for _ in range(count):
            old_low = low
            interval = high - old_low
            found = False
            for symbol, cumulative_low, cumulative_high in model:
                symbol_low = old_low + interval * Fraction(cumulative_low, count)
                symbol_high = old_low + interval * Fraction(cumulative_high, count)
                if symbol_low <= encoded_value < symbol_high:
                    decoded.append(symbol)
                    low, high = symbol_low, symbol_high
                    found = True
                    break
            if not found:
                return -1, b""
        return len(decoded), bytes(decoded)

    if algorithm == "aho_corasick":
        maximum_length = 2 + 16 + 16 * 32 + 256
        if (not isinstance(values, list) or len(values) < 3 or len(values) > maximum_length
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        pattern_count, text_length = values[:2]
        if not 1 <= pattern_count <= 16 or not 0 <= text_length <= 256 or len(values) < 2 + pattern_count:
            return -1, b""
        pattern_lengths = values[2:2 + pattern_count]
        if (len(pattern_lengths) != pattern_count
                or any(not 1 <= length <= 32 for length in pattern_lengths)):
            return -1, b""
        text_start = 2 + pattern_count + sum(pattern_lengths)
        if len(values) != text_start + text_length:
            return -1, b""
        pattern_bytes_start = 2 + pattern_count
        patterns = []
        for pattern_length in pattern_lengths:
            pattern = values[pattern_bytes_start:pattern_bytes_start + pattern_length]
            if any(not 1 <= byte <= 127 for byte in pattern):
                return -1, b""
            patterns.append(bytes(pattern))
            pattern_bytes_start += pattern_length
        if len(set(patterns)) != pattern_count:
            return -1, b""
        text_values = values[text_start:]
        if any(not 1 <= byte <= 127 for byte in text_values):
            return -1, b""
        text = bytes(text_values)
        counts = [
            sum(text[index:index + len(pattern)] == pattern
                for index in range(len(text) - len(pattern) + 1))
            for pattern in patterns
        ]
        output = struct.pack("<" + "q" * pattern_count, *counts)
        return len(output), output

    if algorithm == "z_function":
        if (not isinstance(values, list) or len(values) > 256
                or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
            return -1, b""
        z_values = [0] * len(values)
        for index in range(1, len(values)):
            match_length = 0
            while (index + match_length < len(values)
                   and values[match_length] == values[index + match_length]):
                match_length += 1
            z_values[index] = match_length
        output = b"".join(struct.pack("<q", value) for value in z_values)
        return len(output), output

    if algorithm == "infix_to_postfix_conversion":
        if (not isinstance(values, list) or not values or len(values) > 257
                or any(type(value) is not int for value in values)):
            return -1, b""
        expression_length = values[0]
        expression = values[1:]
        if (not 0 <= expression_length <= 256 or len(expression) != expression_length
                or any(not (48 <= value <= 57 or 65 <= value <= 90 or 97 <= value <= 122
                            or value in (40, 41, 42, 43, 45, 47, 94))
                       for value in expression)):
            return -1, b""

        precedence = {43: 1, 45: 1, 42: 2, 47: 2, 94: 3}
        postfix: list[int] = []
        operators: list[int] = []
        expect_operand = True
        for value in expression:
            if (48 <= value <= 57 or 65 <= value <= 90 or 97 <= value <= 122):
                if not expect_operand:
                    return -1, b""
                postfix.append(value)
                expect_operand = False
            elif value == 40:  # (
                if not expect_operand:
                    return -1, b""
                operators.append(value)
            elif value == 41:  # )
                if expect_operand:
                    return -1, b""
                while operators and operators[-1] != 40:
                    postfix.append(operators.pop())
                if not operators:
                    return -1, b""
                operators.pop()
                expect_operand = False
            else:
                if expect_operand:
                    return -1, b""
                while (operators and operators[-1] != 40
                       and (precedence[operators[-1]] > precedence[value]
                            or (precedence[operators[-1]] == precedence[value] and value != 94))):
                    postfix.append(operators.pop())
                operators.append(value)
                expect_operand = True
        if expect_operand:
            if expression:
                return -1, b""
        while operators:
            if operators[-1] == 40:
                return -1, b""
            postfix.append(operators.pop())
        output = b" ".join(bytes((value,)) for value in postfix) + b"\0"
        return len(output), output

    if algorithm in {"binary_or_operator", "binary_xor_operator"}:
        if (len(values) != 2
                or any(type(value) is not int or not 0 <= value <= 2**31 - 1 for value in values)):
            return -1, b""
        left, right = values
        result = left | right if algorithm == "binary_or_operator" else left ^ right
        width = max(1, left.bit_length(), right.bit_length())
        output = b"0b" + format(result, f"0{width}b").encode("ascii")
        return len(output), output

    if algorithm == "shortest_coprime_segment":
        if (not isinstance(values, list) or len(values) > 128
                or any(type(value) is not int or not 1 <= value <= 1000 for value in values)):
            return -1, b""
        best_start = -1
        best_length = len(values) + 1
        for end in range(len(values)):
            segment_gcd = 0
            for start in range(end, -1, -1):
                segment_gcd = math.gcd(segment_gcd, values[start])
                if segment_gcd == 1:
                    length = end - start + 1
                    if length < best_length:
                        best_start = start
                        best_length = length
                    break
        if best_start < 0:
            return 0, b""
        result = values[best_start:best_start + best_length]
        output = struct.pack("<" + "q" * len(result), *result)
        return len(output), output

    if algorithm == "prefix_sum":
        if (not isinstance(values, list) or len(values) < 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        operation, count = values[0], values[1]
        if operation not in (0, 1, 2) or not 0 <= count <= 256:
            return -1, b""
        extra = 2 if operation == 1 else 1 if operation == 2 else 0
        if len(values) != 2 + count + extra or (operation == 1 and count == 0):
            return -1, b""
        array = values[2:2 + count]
        if any(not -(2**31) <= value <= 2**31 - 1 for value in array):
            return -1, b""
        prefix = [0]
        for value in array:
            prefix.append(prefix[-1] + value)
        if operation == 0:
            words = prefix[1:]
        elif operation == 1:
            left, right = values[2 + count:4 + count]
            if not 0 <= left <= right < count:
                return -1, b""
            words = [prefix[right + 1] - prefix[left]]
        else:
            target = values[2 + count]
            if not -(10**12) <= target <= 10**12:
                return -1, b""
            prior: set[int] = {0}
            found = False
            for current in prefix[1:]:
                if current - target in prior:
                    found = True
                    break
                prior.add(current)
            words = [int(found)]
        output = b"".join(struct.pack("<q", word) for word in words)
        return len(words), output

    if algorithm == "max_heap":
        if (not isinstance(values, list) or len(values) < 1
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        operation_count = values[0]
        if not 0 <= operation_count <= 512 or len(values) != 1 + 2 * operation_count:
            return -1, b""
        inserted = 0
        heap: list[int] = []
        results: list[int] = []
        for index in range(operation_count):
            operation = values[1 + 2 * index]
            value = values[2 + 2 * index]
            if operation == 0:
                inserted += 1
                if inserted > 256 or not -(2**31) <= value <= 2**31 - 1:
                    return -1, b""
                heapq.heappush(heap, -value)
            elif operation in (1, 2):
                if value != 0:
                    return -1, b""
                if not heap:
                    results.append(-(2**63))
                elif operation == 1:
                    results.append(-heap[0])
                else:
                    results.append(-heapq.heappop(heap))
            else:
                return -1, b""
        output = b"".join(struct.pack("<q", result) for result in results)
        return len(results), output

    if algorithm == "range_minimum_query":
        if (not isinstance(values, list) or len(values) < 5
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count = values[0]
        if not 1 <= count <= 64 or len(values) < count + 3:
            return -1, b""
        array = values[1:1 + count]
        if any(not -1000 <= value <= 1000 for value in array):
            return -1, b""
        query_count = values[1 + count]
        if not 1 <= query_count <= 64 or len(values) != 2 + count + 2 * query_count:
            return -1, b""
        answers = []
        for index in range(query_count):
            start, end = values[2 + count + 2 * index:4 + count + 2 * index]
            if not 0 <= start < end <= count:
                answers.append(-(2**63))
            else:
                answers.append(min(array[start:end]))
        output = b"".join(struct.pack("<q", answer) for answer in answers)
        return len(output), output

    if algorithm == "windowed_median":
        if (not isinstance(values, list) or len(values) < 3
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        window_size, stream_length = values[:2]
        if (not 1 <= window_size <= 64 or not 1 <= stream_length <= 128
                or len(values) != stream_length + 2):
            return -1, b""
        stream = values[2:]
        if any(not -1_000_000 <= value <= 1_000_000 for value in stream):
            return -1, b""
        medians = []
        for index in range(stream_length):
            start = max(0, index + 1 - window_size)
            ordered = sorted(stream[start:index + 1])
            middle = len(ordered) // 2
            if len(ordered) % 2:
                median = float(ordered[middle])
            else:
                median = 0.5 * ordered[middle - 1] + 0.5 * ordered[middle]
            medians.append(struct.pack("<d", median))
        output = b"".join(medians)
        return len(output), output

    if algorithm == "aho_corasick":
        if (not isinstance(values, list) or len(values) < 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        pattern_count, text_length = values[:2]
        if (not 1 <= pattern_count <= 16 or not 0 <= text_length <= 256
                or len(values) < 2 + pattern_count):
            return -1, b""
        pattern_lengths = values[2:2 + pattern_count]
        if any(not 1 <= length <= 32 for length in pattern_lengths):
            return -1, b""
        cursor = 2 + pattern_count
        patterns = []
        for length in pattern_lengths:
            if length > len(values) - cursor:
                return -1, b""
            pattern = values[cursor:cursor + length]
            if any(not 1 <= byte <= 127 for byte in pattern):
                return -1, b""
            patterns.append(bytes(pattern))
            cursor += length
        if text_length != len(values) - cursor:
            return -1, b""
        text = values[cursor:]
        if any(not 1 <= byte <= 127 for byte in text) or len(set(patterns)) != pattern_count:
            return -1, b""
        text_bytes = bytes(text)
        counts = []
        for pattern in patterns:
            counts.append(sum(
                text_bytes.startswith(pattern, start)
                for start in range(len(text_bytes) - len(pattern) + 1)
            ))
        output = b"".join(struct.pack("<q", count) for count in counts)
        return len(output), output

    if algorithm == "volume_conversions":
        if (not isinstance(values, list) or len(values) != 3
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        value, from_unit, to_unit = values
        if (not 0 <= value <= 1000 or not 0 <= from_unit <= 2
                or not 0 <= to_unit <= 2 or from_unit == to_unit):
            return -1, b""
        factor_to_cubic_meters = (1.0, 0.001, 1.0)
        cubic_meters = float(value) * factor_to_cubic_meters[from_unit]
        converted = cubic_meters / factor_to_cubic_meters[to_unit]
        output = struct.pack("<d", converted)
        return len(output), output

    if algorithm == "binary_and_operator":
        if (not isinstance(values, list) or len(values) != 2
                or any(type(value) is not int or not 0 <= value <= 2**31 - 1 for value in values)):
            return -1, b""
        first, second = values
        width = max(1, first.bit_length(), second.bit_length())
        output = f"0b{first & second:0{width}b}".encode("ascii")
        return len(output), output

    if algorithm == "capitalize":
        if (not isinstance(values, list) or len(values) > 256
                or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
            return -1, b""
        output = bytearray(values)
        if output and ord("a") <= output[0] <= ord("z"):
            output[0] -= 32
        return len(output), bytes(output)

    if algorithm == "sliding_window_maximum":
        max_length = 1024
        if (not isinstance(values, list) or len(values) < 2 or len(values) > max_length + 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count, window = values[:2]
        if not 0 <= count <= max_length or not 1 <= window <= max_length or len(values) != count + 2:
            return -1, b""
        array = values[2:]
        if any(not -(2**31) <= value <= 2**31 - 1 for value in array):
            return -1, b""
        if count < window:
            return 0, b""
        candidates: deque[int] = deque()
        maxima: list[int] = []
        for index, value in enumerate(array):
            while candidates and candidates[0] <= index - window:
                candidates.popleft()
            while candidates and array[candidates[-1]] < value:
                candidates.pop()
            candidates.append(index)
            if index >= window - 1:
                maxima.append(array[candidates[0]])
        output = b"".join(struct.pack("<q", maximum) for maximum in maxima)
        return len(maxima), output

    if algorithm == "dynamic_array":
        max_operations = 128
        max_elements = 64
        if (not isinstance(values, list) or not 1 <= len(values) <= 1 + 3 * max_operations
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        operation_count = values[0]
        if not 0 <= operation_count <= max_operations:
            return -1, b""
        state: list[int] = []
        query_results: list[int] = []
        capacity = 16
        cursor = 1
        for _ in range(operation_count):
            if cursor >= len(values):
                return -1, b""
            operation = values[cursor]
            cursor += 1
            if operation == 0:
                if cursor >= len(values) or len(state) >= max_elements:
                    return -1, b""
                if len(state) == capacity:
                    capacity *= 2
                state.append(values[cursor])
                cursor += 1
            elif operation == 1:
                if cursor + 1 >= len(values):
                    return -1, b""
                index, value = values[cursor:cursor + 2]
                cursor += 2
                if not 0 <= index < len(state):
                    return -1, b""
                state[index] = value
            elif operation == 2:
                if cursor >= len(values):
                    return -1, b""
                index = values[cursor]
                cursor += 1
                if not 0 <= index < len(state):
                    return -1, b""
                query_results.append(state[index])
            elif operation == 3:
                query_results.append(len(state))
            else:
                return -1, b""
        if cursor != len(values):
            return -1, b""
        words = [len(query_results), *query_results, len(state), *state]
        output = b"".join(struct.pack("<q", word) for word in words)
        return len(words), output

    if algorithm == "decimal_to_fraction":
        if (not isinstance(values, list) or len(values) != 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mantissa, decimal_places = values
        if not 0 <= decimal_places <= 4:
            return -1, b""
        scale = 10**decimal_places
        if (abs(mantissa) > 1_000_000 * scale
                or mantissa % (5**decimal_places) != 0):
            return -1, b""

        # Match the bounded exact-binary subset of the pinned float-based sources.
        value = float(mantissa) / scale
        if value.is_integer():
            numerator, denominator = int(value), 1
        else:
            decimal_text = str(value)
            fractional_digits = decimal_text.partition(".")[2].rstrip("0")
            if not fractional_digits or "e" in decimal_text.lower():
                return -1, b""
            decimal_scale = 10**len(fractional_digits)
            scaled_value = int(value * decimal_scale)
            divisor = math.gcd(abs(scaled_value), decimal_scale)
            numerator = scaled_value // divisor
            denominator = decimal_scale // divisor
        return 16, struct.pack("<qq", numerator, denominator)

    if algorithm == "infix_to_prefix":
        if (not isinstance(values, list) or len(values) > 256
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        if not values:
            return 0, b""
        operators = {ord("+"), ord("-"), ord("*"), ord("/"), ord("^")}

        def parse_expression(index: int) -> tuple[bytes, int] | None:
            if index >= len(values):
                return None
            token = values[index]
            if 48 <= token <= 57 or 65 <= token <= 90 or 97 <= token <= 122:
                return bytes((token,)), index + 1
            if token != ord("("):
                return None
            left = parse_expression(index + 1)
            if left is None:
                return None
            left_prefix, operator_index = left
            if operator_index >= len(values) or values[operator_index] not in operators:
                return None
            operator = values[operator_index]
            right = parse_expression(operator_index + 1)
            if right is None:
                return None
            right_prefix, close_index = right
            if close_index >= len(values) or values[close_index] != ord(")"):
                return None
            return bytes((operator,)) + left_prefix + right_prefix, close_index + 1

        parsed = parse_expression(0)
        if parsed is None or parsed[1] != len(values):
            return -1, b""
        output = parsed[0]
        return len(output), output

    if algorithm == "geometric_series":
        if (not isinstance(values, list) or len(values) != 3
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        term_count, first_term, common_ratio = values
        if (not 0 <= term_count <= 16 or not 1 <= first_term <= 8
                or not 1 <= common_ratio <= 4):
            return -1, b""
        terms = []
        term = float(first_term)
        for _ in range(term_count):
            terms.append(term)
            term *= float(common_ratio)
        output = struct.pack("<" + "d" * term_count, *terms)
        return len(output), output

    if algorithm == "assembly_line_scheduling":
        if (not isinstance(values, list) or len(values) < 7
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        station_count = values[0]
        if not 1 <= station_count <= 64 or len(values) != 4 * station_count + 3:
            return -1, b""
        if any(not 0 <= cost <= 1000 for cost in values[1:]):
            return -1, b""

        n = station_count
        a0 = 1
        a1 = a0 + n
        t0 = a1 + n
        t1 = t0 + n - 1
        entry = t1 + n - 1
        line0 = values[entry] + values[a0]
        line1 = values[entry + 1] + values[a1]
        for station in range(1, n):
            next0 = min(line0 + values[a0 + station],
                        line1 + values[t1 + station - 1] + values[a0 + station])
            next1 = min(line1 + values[a1 + station],
                        line0 + values[t0 + station - 1] + values[a1 + station])
            line0, line1 = next0, next1
        answer = min(line0 + values[entry + 2], line1 + values[entry + 3])
        return 4, struct.pack("<i", answer)

    if algorithm == "reverse_string":
        if (not isinstance(values, list) or not 1 <= len(values) <= 257
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        byte_length = values[0]
        text_values = values[1:]
        if (not 0 <= byte_length <= 256 or len(text_values) != byte_length
                or any(not 0x21 <= byte <= 0x7E for byte in text_values)):
            return -1, b""
        output = bytes(reversed(text_values)) + b"\0"
        return byte_length, output

    if algorithm == "title_case_conversion":
        if (not isinstance(values, list) or not 1 <= len(values) <= 257
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        byte_length = values[0]
        text_values = values[1:]
        if not 0 <= byte_length <= 256 or len(text_values) != byte_length:
            return -1, b""

        output = bytearray()
        at_word_start = True
        for index, value in enumerate(text_values):
            if 65 <= value <= 90 or 97 <= value <= 122:
                if at_word_start:
                    output.append(value - 32 if 97 <= value <= 122 else value)
                    at_word_start = False
                else:
                    output.append(value + 32 if 65 <= value <= 90 else value)
                continue
            if (value == 32 and index > 0 and index + 1 < byte_length
                    and text_values[index - 1] != 32):
                output.append(32)
                at_word_start = True
                continue
            return -1, b""

        output.append(0)
        return byte_length, bytes(output)

    if algorithm == "aatree":
        if (not isinstance(values, list) or not 1 <= len(values) <= 513
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        operation_count = values[0]
        if not 0 <= operation_count <= 256 or len(values) != 1 + 2 * operation_count:
            return -1, b""
        contents: set[int] = set()
        answers: list[int] = []
        for operation in range(operation_count):
            opcode, raw_key = values[1 + 2 * operation:3 + 2 * operation]
            if not 0 <= opcode <= 4:
                return -1, b""
            if opcode <= 2 and not -(2**31) <= raw_key <= 2**31 - 1:
                return -1, b""
            if opcode >= 3 and raw_key != 0:
                return -1, b""
            if opcode == 0:
                if raw_key in contents:
                    return -1, b""
                contents.add(raw_key)
                answers.append(len(contents))
            elif opcode == 1:
                if raw_key not in contents:
                    return -1, b""
                contents.remove(raw_key)
                answers.append(len(contents))
            elif opcode == 2:
                answers.append(int(raw_key in contents))
            elif not contents:
                return -1, b""
            elif opcode == 3:
                answers.append(min(contents))
            else:
                answers.append(max(contents))
        output = b"".join(answer.to_bytes(4, "little", signed=True) for answer in answers)
        return len(output), output

    if algorithm == "adaline_learning":
        if (not isinstance(values, list) or not 5 <= len(values) <= 293
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        sample_count, feature_count, eta_numerator, eta_shift, max_iterations = values[:5]
        if (not 1 <= sample_count <= 32 or not 1 <= feature_count <= 8
                or eta_numerator < 1 or not 1 <= eta_shift <= 12
                or not 1 <= max_iterations <= 500
                or eta_numerator >= 1 << eta_shift
                or len(values) != 5 + sample_count * (feature_count + 1)):
            return -1, b""
        rows = []
        for sample in range(sample_count):
            row = values[5 + sample * (feature_count + 1):
                         5 + (sample + 1) * (feature_count + 1)]
            features, label = row[:-1], row[-1]
            if any(not -16 <= feature <= 16 for feature in features) or label not in (-1, 1):
                return -1, b""
            rows.append((features, label))

        scale = 1 << eta_shift
        weights = [scale] * feature_count
        bias = scale
        iterations = 0
        for _ in range(max_iterations):
            mistakes = 0
            for features, label in rows:
                score = bias + sum(feature * weight for feature, weight in zip(features, weights))
                prediction = 1 if score > 0 else -1
                error = label - prediction
                if error:
                    mistakes += 1
                    correction = eta_numerator * error
                    weights = [weight + correction * feature
                               for weight, feature in zip(weights, features)]
                    bias += correction
            iterations += 1
            if mistakes == 0:
                break

        results = [iterations, *weights, bias]
        for features, _ in rows:
            score = bias + sum(feature * weight for feature, weight in zip(features, weights))
            results.append(1 if score > 0 else -1)
        output = b"".join(result.to_bytes(4, "little", signed=True) for result in results)
        return len(output), output

    if algorithm == "adfgvxcipher":
        if (not isinstance(values, list) or len(values) < 3
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mode, text_length, key_length = values[:3]
        if mode not in (0, 1) or not 1 <= key_length <= 16:
            return -1, b""
        if (not 0 <= text_length <= (256 if mode == 0 else 512)
                or len(values) != 3 + text_length + key_length):
            return -1, b""
        text_values = values[3:3 + text_length]
        key_values = values[3 + text_length:]
        if (any(not 0 <= byte <= 127 for byte in [*text_values, *key_values])
                or any(not 65 <= byte <= 90 for byte in key_values)
                or len(set(key_values)) != key_length):
            return -1, b""
        key = bytes(key_values).decode("ascii")
        square = (b"NA1C3H", b"8TB2OM", b"E5WRPD", b"4F67GI", b"9J0KLQ", b"SUVXYZ")
        labels = "ADFGVX"
        if mode == 0:
            plaintext = bytes(byte - 32 if 97 <= byte <= 122 else byte for byte in text_values)
            clean = bytes(byte for byte in plaintext if 65 <= byte <= 90 or 48 <= byte <= 57)
            reverse_square = {square[row][column]: labels[row] + labels[column]
                              for row in range(6) for column in range(6)}
            fractionated = "".join(reverse_square[byte] for byte in clean)
            rows = (len(fractionated) + key_length - 1) // key_length
            table = [["_"] * key_length for _ in range(rows)]
            for index, character in enumerate(fractionated):
                table[index // key_length][index % key_length] = character
            output_text = "".join(
                table[row][key.index(character)]
                for character in sorted(key) for row in range(rows)
                if table[row][key.index(character)] != "_")
        else:
            ciphertext = bytes(text_values).decode("ascii")
            if len(ciphertext) % 2 or any(character not in labels for character in ciphertext):
                return -1, b""
            rows = (len(ciphertext) + key_length - 1) // key_length
            table = [["_"] * key_length for _ in range(rows)]
            source_index = 0
            for character in sorted(key):
                column = key.index(character)
                for row in range(rows):
                    if source_index < len(ciphertext):
                        table[row][column] = ciphertext[source_index]
                        source_index += 1
            fractionated = "".join(character for row in table for character in row if character != "_")
            square_lookup = {labels[row] + labels[column]: square[row][column]
                             for row in range(6) for column in range(6)}
            output_text = "".join(chr(square_lookup[fractionated[index:index + 2]])
                                  for index in range(0, len(fractionated), 2))
        output = output_text.encode("ascii")
        return len(output), output

    if algorithm == "all_construct":
        if (not isinstance(values, list) or not 2 <= len(values) <= 36
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        target_length = values[0]
        if not 0 <= target_length <= 6 or len(values) < 2 + target_length:
            return -1, b""
        target_values = values[1:1 + target_length]
        if any(not 97 <= value <= 122 for value in target_values):
            return -1, b""
        target = bytes(target_values)
        position = 1 + target_length
        if position >= len(values) or not 0 <= values[position] <= 4:
            return -1, b""
        word_count = values[position]
        position += 1
        words: list[bytes] = []
        for _ in range(word_count):
            if position >= len(values) or not 1 <= values[position] <= 6:
                return -1, b""
            word_length = values[position]
            position += 1
            if word_length > len(values) - position:
                return -1, b""
            word_values = values[position:position + word_length]
            if any(not 97 <= value <= 122 for value in word_values):
                return -1, b""
            words.append(bytes(word_values))
            position += word_length
        if position != len(values):
            return -1, b""

        constructions: list[list[list[bytes]]] = [[] for _ in range(target_length + 1)]
        constructions[0] = [[]]
        for start in range(target_length + 1):
            for word in words:
                if target.startswith(word, start):
                    end = start + len(word)
                    if end <= target_length:
                        for prefix in constructions[start]:
                            constructions[end].append([*prefix, word])
        rows = constructions[target_length]
        output = bytearray()
        for row in rows:
            output.append(len(row))
            for word in row:
                output.append(len(word))
                output.extend(word)
        return len(rows), bytes(output)

    if algorithm in {"a5_cipher", "a5_key_stream_generator"}:
        is_cipher = algorithm == "a5_cipher"
        if (not isinstance(values, list) or len(values) < 3
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        block_count = values[2]
        expected_length = 3 + 4 * block_count if is_cipher else 3
        if not 1 <= block_count <= 4 or len(values) != expected_length:
            return -1, b""

        def parity(number: int) -> int:
            return bin(number).count("1") & 1

        def push(register: int, width: int, bit: int) -> int:
            return ((register << 1) | bit) & ((1 << width) - 1)

        def initialize(key: int, frame: int) -> list[int]:
            registers = [0, 0, 0]
            widths = (19, 22, 23)
            tap_masks = ((1 << 13) | (1 << 16) | (1 << 17) | (1 << 18),
                         (1 << 20) | (1 << 21),
                         (1 << 7) | (1 << 20) | (1 << 21) | (1 << 22))
            for key_bit in range(63, -1, -1):
                bit = (key >> key_bit) & 1
                for index in range(3):
                    registers[index] = push(registers[index], widths[index],
                                            bit ^ parity(registers[index] & tap_masks[index]))
            for frame_bit in range(21, -1, -1):
                bit = (frame >> frame_bit) & 1
                for index in range(3):
                    registers[index] = push(registers[index], widths[index],
                                            bit ^ parity(registers[index] & tap_masks[index]))
            return registers

        def clock(registers: list[int]) -> int:
            widths = (19, 22, 23)
            clock_positions = (8, 10, 10)
            tap_masks = ((1 << 13) | (1 << 16) | (1 << 17) | (1 << 18),
                         (1 << 20) | (1 << 21),
                         (1 << 7) | (1 << 20) | (1 << 21) | (1 << 22))
            clock_bits = [(registers[index] >> clock_positions[index]) & 1 for index in range(3)]
            majority = int(sum(clock_bits) >= 2)
            output_bit = ((registers[0] >> 18) ^ (registers[1] >> 21) ^ (registers[2] >> 22)) & 1
            for index in range(3):
                if clock_bits[index] == majority:
                    feedback = parity(registers[index] & tap_masks[index])
                    registers[index] = push(registers[index], widths[index], feedback)
            return output_bit

        key = values[0] & ((1 << 64) - 1)
        frame = values[1] & ((1 << 22) - 1)
        bytes_per_block = 32 if is_cipher else 29
        output = bytearray(bytes_per_block * block_count)
        for block in range(block_count):
            registers = initialize(key, frame)
            for _ in range(100):
                clock(registers)
            base = bytes_per_block * block
            words = ([values[3 + 4 * block + index] & ((1 << 64) - 1) for index in range(4)]
                     if is_cipher else [])
            for bit_index in range(228):
                stream_bit = clock(registers)
                if is_cipher:
                    plaintext_bit = (words[bit_index // 64] >> (bit_index % 64)) & 1
                    stream_bit ^= plaintext_bit
                output[base + bit_index // 8] |= stream_bit << (bit_index % 8)
            if is_cipher:
                for bit_index in range(228, 256):
                    plaintext_bit = (words[bit_index // 64] >> (bit_index % 64)) & 1
                    output[base + bit_index // 8] |= plaintext_bit << (bit_index % 8)
            for frame_bit in range(21, -1, -1):
                mask = 1 << frame_bit
                if frame & mask:
                    frame &= ~mask
                else:
                    frame |= mask
                    break
        return len(output), bytes(output)

    if algorithm == "binary_shifts":
        if (not isinstance(values, list) or len(values) != 3
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        operation, number, shift = values
        if (operation not in (0, 1, 2) or not -(2**31) < number <= 2**31 - 1
                or not 0 <= shift <= 31 or (operation < 2 and number < 0)):
            return -1, b""
        if operation == 0:
            result = bin(number) + "0" * shift
        elif operation == 1:
            result = bin(number >> shift)
        else:
            if number >= 0:
                bits = "0" + bin(number)[2:]
            else:
                bit_length = len(bin(number)[3:])
                complement_text = bin(abs(number) - (1 << bit_length))[3:]
                bits = "1" + "0" * max(0, bit_length - len(complement_text)) + complement_text
            if shift >= len(bits):
                shifted = bits[0] * len(bits)
            else:
                shifted = bits[0] * shift + bits[:len(bits) - shift]
            result = "0b" + shifted
        output = result.encode("ascii")
        return len(output), output

    if algorithm == "matrix_addition":
        if (not isinstance(values, list) or len(values) < 4
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -2, b""
        rows_a, columns_a = values[:2]
        if (not 0 <= rows_a <= 16 or not 0 <= columns_a <= 16
                or (rows_a == 0 and columns_a != 0)):
            return -2, b""
        cells_a = rows_a * columns_a
        second_header = 2 + cells_a
        if second_header + 2 > len(values):
            return -2, b""
        rows_b, columns_b = values[second_header:second_header + 2]
        if (not 0 <= rows_b <= 16 or not 0 <= columns_b <= 16
                or (rows_b == 0 and columns_b != 0)):
            return -2, b""
        cells_b = rows_b * columns_b
        if len(values) != second_header + 2 + cells_b:
            return -2, b""
        if rows_a != rows_b or columns_a != columns_b:
            return -1, b""
        first = values[2:second_header]
        second = values[second_header + 2:]
        if any(not -(2**31) <= value <= 2**31 - 1 for value in [*first, *second]):
            return -2, b""
        sums = [((left + right + 2**31) & 0xFFFFFFFF) - 2**31
                for left, right in zip(first, second)]
        output = b"".join(struct.pack("<i", value) for value in sums)
        return len(sums), output

    if algorithm == "binary_tree_to_string":
        if (not isinstance(values, list) or len(values) < 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count, root = values[:2]
        if not 0 <= count <= 127 or len(values) != 2 + 3 * count:
            return -1, b""
        nodes = [values[index:index + 3] for index in range(2, len(values), 3)]
        if count == 0:
            return (0, b"") if root == -1 else (-1, b"")
        if not 0 <= root < count:
            return -1, b""
        parents = [0] * count
        for value, left, right in nodes:
            if not -(2**31) <= value <= 2**31 - 1:
                return -1, b""
            for child in (left, right):
                if child < -1 or child >= count:
                    return -1, b""
                if child >= 0:
                    parents[child] += 1
                    if parents[child] > 1:
                        return -1, b""
        if parents[root] != 0 or any(parents[index] != 1 for index in range(count) if index != root):
            return -1, b""
        reachable: set[int] = set()
        pending = [root]
        for node in pending:
            if node in reachable:
                return -1, b""
            reachable.add(node)
            _value, left, right = nodes[node]
            if left >= 0:
                pending.append(left)
            if right >= 0:
                pending.append(right)
        if len(reachable) != count:
            return -1, b""

        def serialize(node: int) -> str:
            value, left, right = nodes[node]
            result = str(value)
            if left >= 0:
                result += "(" + serialize(left) + ")"
            elif right >= 0:
                result += "()"
            if right >= 0:
                result += "(" + serialize(right) + ")"
            return result

        output = serialize(root).encode("ascii")
        return len(output), output

    if algorithm == "print_multiplication_table":
        if (not isinstance(values, list) or len(values) != 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        number, terms = values
        if not -1_000_000 <= number <= 1_000_000 or not -20 <= terms <= 20:
            return -1, b""
        output = "\n".join(f"{number} * {index} = {number * index}"
                            for index in range(1, terms + 1)).encode("ascii")
        return len(output), output

    if algorithm == "create_binary_tree_from_inorder_preorder":
        if (not isinstance(values, list) or not 1 <= len(values) <= 127
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count = values[0]
        if (not 0 <= count <= 63 or len(values) != 1 + 2 * count
                or any(not -(2**31) <= value <= 2**31 - 1 for value in values[1:])):
            return -1, b""
        preorder = values[1:1 + count]
        inorder = values[1 + count:]
        if len(set(preorder)) != count or len(set(inorder)) != count or set(preorder) != set(inorder):
            return -1, b""
        preorder_index = 0

        def serialize_tree(start: int, end: int) -> bytes:
            nonlocal preorder_index
            if start == end:
                return b"\0"
            if preorder_index >= count:
                raise ValueError("preorder ended before the inorder interval")
            root_value = preorder[preorder_index]
            preorder_index += 1
            try:
                root_position = inorder.index(root_value, start, end)
            except ValueError as error:
                raise ValueError("preorder root is absent from the current inorder interval") from error
            return (b"\1" + struct.pack("<i", root_value)
                    + serialize_tree(start, root_position)
                    + serialize_tree(root_position + 1, end))

        try:
            output = serialize_tree(0, count)
        except ValueError:
            return -1, b""
        if preorder_index != count:
            return -1, b""
        return count, output

    if algorithm == "unique_permutation":
        if (not isinstance(values, list) or not 1 <= len(values) <= 7
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count, items = values[0], values[1:]
        if (not 0 <= count <= 6 or len(items) != count
                or any(not 0 <= value <= 127 for value in items)):
            return -1, b""
        rows = sorted(set(permutations(items)))
        output = b"".join(bytes(row) for row in rows)
        return len(rows), output

    if algorithm == "arrays_intersection":
        if (not isinstance(values, list) or not 3 <= len(values) <= 195
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        arrays = []
        position = 0
        for _ in range(3):
            if position >= len(values) or not 0 <= values[position] <= 64:
                return -1, b""
            count = values[position]
            position += 1
            if count > len(values) - position:
                return -1, b""
            array = values[position:position + count]
            if any(not -(2**31) <= value <= 2**31 - 1 for value in array):
                return -1, b""
            arrays.append(array)
            position += count
        if position != len(values):
            return -1, b""
        frequencies: dict[int, int] = {}
        for array in arrays:
            for value in array:
                frequencies[value] = frequencies.get(value, 0) + 1
        matches = [value for value, frequency in frequencies.items() if frequency == 3]
        output = b"".join(struct.pack("<i", value) for value in matches)
        return len(matches), output

    if algorithm == "flatten_binarytree_to_linkedlist":
        if (not isinstance(values, list) or not 1 <= len(values) <= 1 + 3 * 1023
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        root = values[0]
        if len(values) == 1:
            return (0, b"") if root == -1 else (-1, b"")
        if (len(values) < 4 or (len(values) - 1) % 3 != 0
                or not -(2**31) <= root <= 2**31 - 1):
            return -1, b""
        nodes = [values[index:index + 3] for index in range(1, len(values), 3)]
        count = len(nodes)
        if (count > 1023 or not 0 <= root < count
                or any(not -(2**31) <= row[0] <= 2**31 - 1
                       or any(child < -1 or child >= count for child in row[1:]) for row in nodes)):
            return -1, b""
        parents = [0] * count
        for _value, left, right in nodes:
            for child in (left, right):
                if child >= 0:
                    parents[child] += 1
        if parents[root] != 0 or any(parents[index] != 1 for index in range(count) if index != root):
            return -1, b""
        preorder: list[int] = []
        stack = [(root, 1)]
        seen: set[int] = set()
        maximum_depth = 0
        while stack:
            node, depth = stack.pop()
            if node in seen:
                return -1, b""
            seen.add(node)
            preorder.append(node)
            maximum_depth = max(maximum_depth, depth)
            _value, left, right = nodes[node]
            if right >= 0:
                stack.append((right, depth + 1))
            if left >= 0:
                stack.append((left, depth + 1))
        if len(seen) != count or maximum_depth > 512:
            return -1, b""
        next_node = {node: preorder[index + 1] if index + 1 < count else -1
                     for index, node in enumerate(preorder)}
        output = b"".join(struct.pack("<qqq", value, -1, next_node[index])
                           for index, (value, _left, _right) in enumerate(nodes))
        return count, output

    if algorithm == "reverse_words":
        if (not isinstance(values, list) or not 1 <= len(values) <= 257
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        byte_length = values[0]
        if (not 0 <= byte_length <= 256 or len(values) != byte_length + 1
                or any(not (value == 32 or 33 <= value <= 126) for value in values[1:])):
            return -1, b""
        text = bytes(values[1:])
        if text and (text[0] == 32 or text[-1] == 32 or b"  " in text):
            return -1, b""
        words = text.split(b" ") if text else []
        output = b" ".join(reversed(words)) + b"\0"
        return len(output) - 1, output

    if algorithm == "serialize_deserialize_binary_tree":
        if (not isinstance(values, list) or not 1 <= len(values) <= 2200
                or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
            return -1, b""
        tokens = bytes(values).split(b",")
        if not tokens or any(token == b"" for token in tokens):
            return -1, b""
        slots = 1
        node_count = 0
        canonical: list[bytes] = []
        whitespace = {9, 10, 11, 12, 13, 32}
        for token in tokens:
            if slots == 0:
                return -1, b""
            slots -= 1
            if token == b"null":
                canonical.append(b"null")
                continue
            start, end = 0, len(token)
            while start < end and token[start] in whitespace:
                start += 1
            while end > start and token[end - 1] in whitespace:
                end -= 1
            if start == end:
                return -1, b""
            negative = token[start] == ord("-")
            if token[start] in (ord("+"), ord("-")):
                start += 1
            if start == end or any(not 48 <= byte <= 57 for byte in token[start:end]):
                return -1, b""
            limit = 2**31 if negative else 2**31 - 1
            number = 0
            for byte in token[start:end]:
                digit = byte - 48
                if number > (limit - digit) // 10:
                    return -1, b""
                number = number * 10 + digit
            number = -number if negative else number
            node_count += 1
            if node_count > 127:
                return -1, b""
            canonical.append(str(number).encode("ascii"))
            slots += 2
        if slots != 0:
            return -1, b""
        output = b",".join(canonical)
        return len(output), output

    if algorithm == "all_subsequences":
        if (not isinstance(values, list) or not 1 <= len(values) <= 9
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count = values[0]
        items = values[1:]
        if (not 0 <= count <= 8 or len(items) != count
                or any(not -(2**31) <= value <= 2**31 - 1 for value in items)):
            return -1, b""
        rows: list[list[int]] = []
        current: list[int] = []

        def enumerate_rows(index: int) -> None:
            if index == count:
                rows.append(current.copy())
                return
            enumerate_rows(index + 1)
            current.append(items[index])
            enumerate_rows(index + 1)
            current.pop()

        enumerate_rows(0)
        output = bytearray()
        for row in rows:
            output.extend(struct.pack("<I", len(row)))
            output.extend(b"".join(struct.pack("<i", value) for value in row))
        return len(rows), bytes(output)

    if algorithm == "all_paths_from_source_to_target":
        if (not isinstance(values, list) or not 4 <= len(values) <= 52
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        vertex_count, edge_count, source, destination = values[:4]
        if (not 1 <= vertex_count <= 8 or not 0 <= edge_count <= 24
                or len(values) != 4 + 2 * edge_count
                or not 0 <= source < vertex_count or not 0 <= destination < vertex_count):
            return -1, b""
        adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
        for index in range(4, len(values), 2):
            start, end = values[index:index + 2]
            if not 0 <= start < vertex_count or not 0 <= end < vertex_count:
                return -1, b""
            adjacency[start].append(end)
        paths: list[list[int]] = []
        path = [source]
        in_path = {source}

        def visit(node: int) -> bool:
            if node == destination:
                if len(paths) == 1000:
                    return False
                paths.append(path.copy())
                return True
            for neighbor in adjacency[node]:
                if neighbor in in_path:
                    continue
                in_path.add(neighbor)
                path.append(neighbor)
                if not visit(neighbor):
                    return False
                path.pop()
                in_path.remove(neighbor)
            return True

        if not visit(source):
            return -2, b""
        output = bytearray(struct.pack("<q", len(paths)))
        for found_path in paths:
            output.extend(struct.pack("<q", len(found_path)))
            output.extend(b"".join(struct.pack("<q", vertex) for vertex in found_path))
        return len(output), bytes(output)

    if algorithm == "alternative_list_arrange":
        if (not isinstance(values, list) or not 2 <= len(values) <= 130
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        first_count = values[0]
        if not 0 <= first_count <= 64 or len(values) < first_count + 2:
            return -1, b""
        first = values[1:1 + first_count]
        second_count_position = 1 + first_count
        second_count = values[second_count_position]
        second = values[second_count_position + 1:]
        if not 0 <= second_count <= 64 or len(second) != second_count:
            return -1, b""
        arranged = []
        for index in range(max(first_count, second_count)):
            if index < first_count:
                arranged.append(first[index])
            if index < second_count:
                arranged.append(second[index])
        output = b"".join(struct.pack("<q", value) for value in arranged)
        return len(arranged), output

    if algorithm == "sorted_arrays_intersection":
        if (not isinstance(values, list) or not 3 <= len(values) <= 195
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        arrays = []
        position = 0
        for _ in range(3):
            if position >= len(values) or not 0 <= values[position] <= 64:
                return -1, b""
            count = values[position]
            position += 1
            if count > len(values) - position:
                return -1, b""
            array = values[position:position + count]
            if (any(not -(2**31) <= value <= 2**31 - 1 for value in array)
                    or any(array[index - 1] >= array[index] for index in range(1, count))):
                return -1, b""
            arrays.append(array)
            position += count
        if position != len(values):
            return -1, b""
        common = sorted(set(arrays[0]).intersection(arrays[1], arrays[2]))
        output = b"".join(struct.pack("<i", value) for value in common)
        return len(common), output

    if algorithm == "cantor_set":
        if (not isinstance(values, list) or len(values) != 3
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        start, end, levels = values
        if not 0 <= start <= end <= 100_000 or not 0 <= levels <= 6:
            return -1, b""
        output = bytearray()

        def append_uint(value: int) -> None:
            output.extend(str(value).encode("ascii"))

        def append_fixed(ticks: int) -> None:
            whole, fraction = divmod(ticks, 1_000_000)
            append_uint(whole)
            output.append(ord("."))
            for divisor in (100_000, 10_000, 1_000, 100, 10, 1):
                output.append(ord("0") + fraction // divisor % 10)

        positions = [0]
        denominator = 1
        span = end - start
        for level in range(levels + 1):
            output.extend(b"Level ")
            append_uint(level)
            output.append(9)
            for position in positions:
                left_numerator = (start * denominator + span * position) * 1_000_000
                right_numerator = (start * denominator + span * (position + 1)) * 1_000_000
                left_ticks = (left_numerator + denominator // 2) // denominator
                right_ticks = (right_numerator + denominator // 2) // denominator
                output.extend(b"\t[")
                append_fixed(left_ticks)
                output.extend(b"] -- [")
                append_fixed(right_ticks)
                output.append(ord("]"))
            output.append(10)
            if level < levels:
                output.append(10)
                positions = [part for position in positions for part in (position * 3, position * 3 + 2)]
                denominator *= 3
        output.append(0)
        return len(output), bytes(output)

    if algorithm == "array_left_rotation_modulo":
        if (not isinstance(values, list) or not 1 <= len(values) <= 1025
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        shift, array = values[0], values[1:]
        if (not -(2**31) <= shift <= 2**31 - 1 or len(array) > 1024
                or any(not -(2**31) <= value <= 2**31 - 1 for value in array)):
            return -1, b""
        if not array or shift <= 0:
            output = array
        else:
            offset = shift % len(array)
            output = array[offset:] + array[:offset]
        return len(output), b"".join(struct.pack("<i", value) for value in output)

    if algorithm == "array_left_rotation":
        if (not isinstance(values, list) or not 1 <= len(values) <= 1025
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        shift, array = values[0], values[1:]
        if (not 0 <= shift <= 1024 or len(array) > 1024
                or any(not -(2**31) <= value <= 2**31 - 1 for value in array)):
            return -1, b""
        if shift >= len(array):
            return 0, b""
        output = array[shift:] + array[:shift]
        return len(output), b"".join(struct.pack("<i", value) for value in output)

    if algorithm == "array_right_rotation":
        if (not isinstance(values, list) or not 1 <= len(values) <= 1025
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        shift, array = values[0], values[1:]
        if (not 0 <= shift <= 1024 or len(array) > 1024
                or any(not -(2**31) <= value <= 2**31 - 1 for value in array)):
            return -1, b""
        if shift >= len(array):
            return 0, b""
        output = array if shift == 0 else array[-shift:] + array[:-shift]
        return len(output), b"".join(struct.pack("<i", value) for value in output)

    if algorithm == "array_right_rotation_modulo":
        if (not isinstance(values, list) or not 2 <= len(values) <= 1025
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        shift, array = values[0], values[1:]
        if (not 0 <= shift <= 2**31 - 1 or len(array) > 1024
                or any(not -(2**31) <= value <= 2**31 - 1 for value in array)):
            return -1, b""
        offset = shift % len(array)
        output = array if offset == 0 else array[-offset:] + array[:-offset]
        return len(output), b"".join(struct.pack("<i", value) for value in output)

    if algorithm == "three_sum_problem":
        if (not isinstance(values, list) or not 2 <= len(values) <= 259
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        target, count = values[:2]
        array = values[2:]
        if (not -(2**31) <= target <= 2**31 - 1 or not 0 <= count <= 257
                or len(array) != count
                or any(not -100_000 <= value <= 100_000 for value in array)):
            return -1, b""
        if count < 3:
            return 0, b""
        ordered = sorted(array)
        triplets: list[tuple[int, int, int]] = []
        for first in range(count - 2):
            if first and ordered[first] == ordered[first - 1]:
                continue
            left, right = first + 1, count - 1
            while left < right:
                total = ordered[first] + ordered[left] + ordered[right]
                if total == target:
                    triplets.append((ordered[first], ordered[left], ordered[right]))
                    left_value, right_value = ordered[left], ordered[right]
                    while left < right and ordered[left] == left_value:
                        left += 1
                    while left < right and ordered[right] == right_value:
                        right -= 1
                elif total < target:
                    left += 1
                else:
                    right -= 1
        output = b"".join(struct.pack("<iii", *triplet) for triplet in triplets)
        return len(triplets), output

    if algorithm == "anagram_dictionary_search":
        if (not isinstance(values, list) or not 2 <= len(values) <= 290
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        dictionary_count, query_length = values[:2]
        if (not 0 <= dictionary_count <= 16 or not 0 <= query_length <= 16
                or len(values) < 2 + query_length):
            return -1, b""
        query_values = values[2:2 + query_length]
        if any(not 97 <= value <= 122 for value in query_values):
            return -1, b""
        position = 2 + query_length
        dictionary: list[bytes] = []
        for _ in range(dictionary_count):
            if position >= len(values) or not 1 <= values[position] <= 16:
                return -1, b""
            word_length = values[position]
            position += 1
            if word_length > len(values) - position:
                return -1, b""
            word_values = values[position:position + word_length]
            if any(not 97 <= value <= 122 for value in word_values):
                return -1, b""
            dictionary.append(bytes(word_values))
            position += word_length
        if position != len(values) or dictionary != sorted(set(dictionary)):
            return -1, b""
        query_signature = sorted(query_values)
        matches = [word for word in dictionary if sorted(word) == query_signature]
        output = b"\n".join(matches) + b"\0"
        return len(output), output

    if algorithm == "detect_anagrams":
        if (not isinstance(values, list) or not 2 <= len(values) <= 290
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        subject_length = values[0]
        if not 0 <= subject_length <= 16 or 1 + subject_length >= len(values):
            return -1, b""
        subject_values = values[1:1 + subject_length]
        if any(not (65 <= value <= 90 or 97 <= value <= 122) for value in subject_values):
            return -1, b""
        position = 1 + subject_length
        candidate_count = values[position]
        position += 1
        if not 0 <= candidate_count <= 16:
            return -1, b""
        subject = bytes(value | 32 for value in subject_values)
        subject_signature = sorted(subject)
        matches = []
        for _ in range(candidate_count):
            if position >= len(values) or not 0 <= values[position] <= 16:
                return -1, b""
            candidate_length = values[position]
            position += 1
            if candidate_length > len(values) - position:
                return -1, b""
            candidate_values = values[position:position + candidate_length]
            if any(not (65 <= value <= 90 or 97 <= value <= 122) for value in candidate_values):
                return -1, b""
            candidate = bytes(candidate_values)
            lowered = bytes(value | 32 for value in candidate)
            if lowered != subject and sorted(lowered) == subject_signature:
                matches.append(candidate)
            position += candidate_length
        if position != len(values):
            return -1, b""
        output = b"\n".join(matches) + b"\0"
        return len(matches), output

    if algorithm == "next_permutation":
        if (not isinstance(values, list) or not 1 <= len(values) <= 129
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count = values[0]
        items = values[1:]
        if (not 0 <= count <= 128 or len(items) != count
                or any(not -(2**31) <= value <= 2**31 - 1 for value in items)):
            return -1, b""
        pivot = count - 2
        while pivot >= 0 and items[pivot] >= items[pivot + 1]:
            pivot -= 1
        if pivot < 0:
            items.reverse()
        else:
            successor = count - 1
            while items[successor] <= items[pivot]:
                successor -= 1
            items[pivot], items[successor] = items[successor], items[pivot]
            items[pivot + 1:] = reversed(items[pivot + 1:])
        output = b"".join(struct.pack("<i", value) for value in items)
        return count, output

    if algorithm == "all_permutations":
        if (not isinstance(values, list) or not 1 <= len(values) <= 7
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count = values[0]
        items = values[1:]
        if (not 0 <= count <= 6 or len(items) != count
                or any(not -(2**31) <= value <= 2**31 - 1 for value in items)):
            return -1, b""
        output = b"".join(struct.pack("<i", value)
                           for row in permutations(items) for value in row)
        return math.factorial(count), output

    if algorithm == "top_k_frequent_words":
        if (not isinstance(values, list) or not 2 <= len(values) <= 1090
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        k, word_count = values[:2]
        if not 0 <= k <= 64 or not 0 <= word_count <= 64:
            return -1, b""
        position = 2
        frequencies: dict[bytes, int] = {}
        for _ in range(word_count):
            if position >= len(values) or not 1 <= values[position] <= 16:
                return -1, b""
            word_length = values[position]
            position += 1
            if word_length > len(values) - position:
                return -1, b""
            word_values = values[position:position + word_length]
            if any(not 97 <= value <= 122 for value in word_values):
                return -1, b""
            word = bytes(word_values)
            frequencies[word] = frequencies.get(word, 0) + 1
            position += word_length
        if position != len(values):
            return -1, b""
        heap = list(frequencies.items())

        def max_heapify(index: int, size: int) -> None:
            violation = index
            left = 2 * index + 1
            right = left + 1
            if left < size and heap[left][1] > heap[violation][1]:
                violation = left
            if right < size and heap[right][1] > heap[violation][1]:
                violation = right
            if violation != index:
                heap[index], heap[violation] = heap[violation], heap[index]
                max_heapify(violation, size)

        for index in range(len(heap) // 2 - 1, -1, -1):
            max_heapify(index, len(heap))
        ranked = []
        size = len(heap)
        for _ in range(min(k, size)):
            ranked.append(heap[0][0])
            if size == 1:
                size = 0
            else:
                heap[0] = heap[size - 1]
                size -= 1
                max_heapify(0, size)
        output = b"\n".join(ranked) + b"\0"
        return len(output), output

    if algorithm == "find_all_duplicates_hash_order":
        if (not isinstance(values, list) or len(values) > 1024
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        frequencies: dict[int, int] = {}
        for value in values:
            frequencies[value] = frequencies.get(value, 0) + 1
        duplicates = [value for value, count in frequencies.items() if count > 1]
        output = b"".join(struct.pack("<q", value) for value in duplicates)
        return len(duplicates), output

    if algorithm == "majority_elements_floor_half":
        if (not isinstance(values, list) or len(values) > 256
                or any(type(value) is not int or not -(2**31) <= value <= 2**31 - 1 for value in values)):
            return -1, b""
        frequencies: dict[int, int] = {}
        for value in values:
            frequencies[value] = frequencies.get(value, 0) + 1
        threshold = len(values) // 2
        majority_values = sorted(value for value, count in frequencies.items() if count >= threshold)
        output = b"".join(struct.pack("<i", value) for value in majority_values)
        return len(majority_values), output

    if algorithm == "infix_to_postfix":
        if (not isinstance(values, list) or not 1 <= len(values) <= 24
                or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
            return -1, b""
        stack: list[int] = []
        output = bytearray()
        expect_operand = True

        def precedence(byte: int) -> int:
            if byte in b"+-":
                return 1
            if byte in b"*/":
                return 2
            return 3

        for byte in values:
            if 48 <= byte <= 57 or 65 <= byte <= 90 or 97 <= byte <= 122:
                if not expect_operand:
                    return -1, b""
                output.append(byte)
                expect_operand = False
            elif byte == ord("("):
                if not expect_operand or len(stack) >= 10:
                    return -1, b""
                stack.append(byte)
            elif byte == ord(")"):
                while stack and stack[-1] != ord("("):
                    output.append(stack.pop())
                if stack:
                    stack.pop()
                expect_operand = False
            elif byte in b"+-*/^":
                if expect_operand:
                    return -1, b""
                while stack and stack[-1] != ord("(") and precedence(byte) <= precedence(stack[-1]):
                    output.append(stack.pop())
                if len(stack) >= 10:
                    return -1, b""
                stack.append(byte)
                expect_operand = True
            else:
                return -1, b""
        if expect_operand:
            return -1, b""
        while stack:
            operator = stack.pop()
            if operator == ord("("):
                return -1, b""
            output.append(operator)
        output.append(0)
        return len(output), bytes(output)

    if algorithm == "infix_to_postfix2":
        if (not isinstance(values, list) or not 1 <= len(values) <= 24
                or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
            return -1, b""
        stack: list[int] = []
        output = bytearray()
        expect_operand = True

        def precedence(byte: int) -> int:
            return 1 if byte in b"*/%" else 0

        for byte in values:
            if 48 <= byte <= 57 or 65 <= byte <= 90 or 97 <= byte <= 122:
                if not expect_operand:
                    return -1, b""
                output.append(byte)
                expect_operand = False
            elif byte == ord("("):
                if not expect_operand or len(stack) >= 10:
                    return -1, b""
                stack.append(byte)
            elif byte == ord(")"):
                if expect_operand or ord("(") not in stack:
                    return -1, b""
                while stack[-1] != ord("("):
                    output.append(stack.pop())
                stack.pop()
                expect_operand = False
            elif byte in b"+-*/%":
                if expect_operand or len(stack) >= 10 and (not stack or stack[-1] == ord("(")):
                    return -1, b""
                while stack and stack[-1] != ord("(") and precedence(byte) <= precedence(stack[-1]):
                    output.append(stack.pop())
                if len(stack) >= 10:
                    return -1, b""
                stack.append(byte)
                expect_operand = True
            else:
                return -1, b""
        if expect_operand:
            return -1, b""
        while stack:
            operator = stack.pop()
            if operator == ord("("):
                return -1, b""
            output.append(operator)
        output.append(0)
        return len(output), bytes(output)

    if algorithm == "format_phone_number":
        if (not isinstance(values, list) or len(values) != 10
                or any(type(value) is not int or not 48 <= value <= 57 for value in values)):
            return -1, b""
        digits = bytes(values)
        output = b"(" + digits[:3] + b") " + digits[3:6] + b"-" + digits[6:]
        return len(output), output

    if algorithm == "check_palindrome2":
        if (not isinstance(values, list) or len(values) > 1024
                or any(type(value) is not int or not 32 <= value <= 126 for value in values)):
            return -1, b""
        normalized = bytes(values).strip(b" ").lower()
        if not normalized or normalized == b"0":
            return -1, b""
        suffix = (b" - a palindrome string.\n" if normalized == normalized[::-1]
                  else b" - not a palindrome string.\n")
        output = normalized + suffix
        return len(output), output

    if algorithm == "first_n_fibonacci":
        if (not isinstance(values, list) or len(values) != 1
                or type(values[0]) is not int or not -(2**63) <= values[0] < 2**63
                or not 3 <= values[0] <= 79):
            return -1, b""
        previous, current = 0, 1
        output = bytearray()
        for _ in range(values[0]):
            output.extend(str(previous).encode("ascii"))
            output.append(0)
            previous, current = current, previous + current
        return len(output), bytes(output)

    if algorithm == "kaprekar_numbers_in_range":
        if (not isinstance(values, list) or len(values) != 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63
                       for value in values)):
            return -1, b""
        start, end = values
        if not 0 <= start <= end <= 100_000:
            return -1, b""
        numbers = []
        for value in range(start, end + 1):
            if value <= 1:
                numbers.append(value)
                continue
            square = value * value
            right_width = len(str(value))
            left, right = divmod(square, 10**right_width)
            if right != 0 and left + right == value:
                numbers.append(value)
        output = b"".join(str(value).encode("ascii") + b"\0" for value in numbers)
        return len(output), output

    if algorithm == "quartile":
        import struct

        if (not isinstance(values, list) or not 2 <= len(values) <= 11
                or any(type(value) is not int or not 0 <= value <= 99 for value in values)):
            return -1, b""
        count = values[0]
        if not 1 <= count <= 10 or len(values) != count + 1:
            return -1, b""
        ordered = sorted(values[1:])
        q1 = ordered[count // 4]
        q3 = ordered[(3 * count) // 4]
        output = struct.pack("<" + "q" * (count + 4), count, *ordered, q1, q3, q3 - q1)
        return len(output), output

    if algorithm == "word_count":
        import struct

        if (not isinstance(values, list) or len(values) < 2
                or len(values) > 1050
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        text_length = values[0]
        if not 0 <= text_length <= 999 or len(values) < text_length + 2:
            return -1, b""
        text_start = 1
        query_length_index = text_start + text_length
        if query_length_index >= len(values):
            return -1, b""
        query_length = values[query_length_index]
        if not 0 <= query_length <= 49 or len(values) != query_length_index + query_length + 1:
            return -1, b""
        text_values = values[text_start:query_length_index]
        query_values = values[query_length_index + 1:]
        if (any(not 1 <= value <= 127 for value in text_values + query_values)):
            return -1, b""
        if len(query_values) > 49:
            return -1, b""
        total_words, matching_words, start = 0, 0, 0
        query = bytes(query_values)
        for end in range(len(text_values) + 1):
            if end == len(text_values) or text_values[end] == 32:
                token_length = end - start
                if token_length > 49:
                    return -1, b""
                if total_words >= 20:
                    return -2, b""
                if bytes(text_values[start:end]) == query:
                    matching_words += 1
                total_words += 1
                start = end + 1
        return 16, struct.pack("<2q", total_words, matching_words)

    if algorithm == "vector_cross_product":
        import math
        import struct

        if (not isinstance(values, list) or len(values) != 6
                or any(type(value) is not int or not -(2**63) <= value < 2**63
                       for value in values)
                or any(abs(value) > 1_000_000 for value in values)):
            return -1, b""
        a0, a1, a2, b0, b1, b2 = values
        cross = (a1 * b2 - a2 * b1,
                 -((a0 * b2) - (a2 * b0)),
                 a0 * b1 - a1 * b0)
        magnitude_micro = math.floor(math.sqrt(
            cross[0] * cross[0] + cross[1] * cross[1] + cross[2] * cross[2]
        ) * 1_000_000 + 0.5)
        output = struct.pack("<4q", *cross, magnitude_micro)
        return len(output), output

    if algorithm == "word_search_generator":
        return word_search_generator_output(values)

    if algorithm == "burrows_wheeler_transform":
        if (not isinstance(values, list) or len(values) < 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        text_length = values[0]
        if not 1 <= text_length <= MAX_BURROWS_WHEELER_LENGTH or len(values) != text_length + 1:
            return -1, b""
        if any(not 0 <= value <= 127 for value in values[1:]):
            return -1, b""
        text = bytes(values[1:])
        order = sorted(range(text_length), key=lambda start: (text[start:] + text[:start], start))
        primary_index = order.index(0)
        output = primary_index.to_bytes(4, "little") + bytes(text[(start - 1) % text_length] for start in order)
        return len(output), output

    if algorithm == "burrows_wheeler_transform_case_insensitive":
        if (not isinstance(values, list) or not values
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        text_length = values[0]
        if not 0 <= text_length <= MAX_BURROWS_WHEELER_LENGTH or len(values) != text_length + 1:
            return -1, b""
        if any(not 0 <= value <= 127 for value in values[1:]):
            return -1, b""
        text = bytes(values[1:])
        fold = lambda byte: byte + 32 if 65 <= byte <= 90 else byte
        order = sorted(range(text_length), key=lambda start: (
            bytes(fold(text[(start + offset) % text_length]) for offset in range(text_length)), start
        )) if text_length else []
        primary_index = 0
        for row, start in enumerate(order):
            if all(text[(start + offset) % text_length] == text[offset]
                   for offset in range(text_length)):
                primary_index = row
        output = primary_index.to_bytes(4, "little") + bytes(
            text[(start - 1) % text_length] for start in order
        ) if text_length else bytes(4)
        return len(output), output

    if algorithm == "baconian_cipher":
        if (not isinstance(values, list) or not 2 <= len(values) <= MAX_BACONIAN_PAYLOAD_LENGTH + 2
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mode, dialect, *payload = values
        if mode not in (0, 1) or dialect not in (0, 1, 2) or any(not 0 <= value <= 127 for value in payload):
            return -1, b""
        output = bytearray()
        if mode == 0:
            if dialect == 0:  # Java: upper-case, discard nonletters, merge I/J.
                for value in payload:
                    upper = value - 32 if 97 <= value <= 122 else value
                    if 65 <= upper <= 90:
                        index = 9 if upper == 73 else upper - 65
                        output.extend(BACONIAN_STANDARD_CODES[index].encode("ascii"))
            elif dialect == 1:  # Python: lower-case table and preserved spaces.
                for value in payload:
                    if value == 32:
                        output.append(32)
                    elif 65 <= value <= 90 or 97 <= value <= 122:
                        lower = value + 32 if value <= 90 else value
                        output.extend(BACONIAN_PYTHON_CODES[chr(lower)].encode("ascii"))
                    else:
                        return -1, b""
            else:  # Rust: A..X codes, nonletters pass through; Y/Z are out of domain.
                for value in payload:
                    upper = value - 32 if 97 <= value <= 122 else value
                    if 65 <= upper <= 90:
                        index = upper - 65
                        if index >= 24:
                            return -1, b""
                        output.extend(BACONIAN_STANDARD_CODES[index].encode("ascii"))
                    else:
                        output.append(value)
            return len(output), bytes(output)

        if dialect == 0:  # Java: reject malformed or unassigned 5-bit groups.
            if len(payload) % 5 != 0 or any(value not in (65, 66) for value in payload):
                return -1, b""
            for start in range(0, len(payload), 5):
                code = 0
                for value in payload[start:start + 5]:
                    code = (code << 1) | (value == 66)
                if code > 25:
                    return -1, b""
                output.append(73 if code in (8, 9) else 65 + code)
        elif dialect == 1:  # Python: strict table decode, spaces collapse to word separators.
            if any(value not in (32, 65, 66) for value in payload):
                return -1, b""
            words = bytes(payload).split()
            inverse = {code.encode("ascii"): letter.encode("ascii")
                       for letter, code in BACONIAN_PYTHON_CODES.items()}
            decoded_words = []
            for word in words:
                if len(word) % 5 != 0:
                    return -1, b""
                decoded = bytearray()
                for start in range(0, len(word), 5):
                    letter = inverse.get(word[start:start + 5])
                    if letter is None:
                        return -1, b""
                    decoded.extend(letter)
                decoded_words.append(bytes(decoded))
            output.extend(b" ".join(decoded_words))
        else:  # Rust: unknown chunks, including a short final chunk, become spaces.
            rust_codes = BACONIAN_STANDARD_CODES[:24]
            inverse = {code.encode("ascii"): 65 + index for index, code in enumerate(rust_codes)}
            coded = bytes(payload)
            for start in range(0, len(coded), 5):
                output.append(inverse.get(coded[start:start + 5], 32))
        return len(output), bytes(output)

    if algorithm == "porta_cipher":
        max_input_length = 3 + MAX_PORTA_TEXT_LENGTH + MAX_PORTA_KEY_LENGTH
        if (not isinstance(values, list) or not 3 <= len(values) <= max_input_length
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mode, text_length, key_length = values[:3]
        if (mode not in (0, 1) or not 0 <= text_length <= MAX_PORTA_TEXT_LENGTH
                or not 0 <= key_length <= MAX_PORTA_KEY_LENGTH
                or len(values) != 3 + text_length + key_length
                or (text_length > 0 and key_length == 0)):
            return -1, b""
        text = values[3:3 + text_length]
        key = values[3 + text_length:]
        if any(not (65 <= value <= 90 or 97 <= value <= 122) for value in text + key):
            return -1, b""
        normalized_key = [value - 32 if value >= 97 else value for value in key]
        output = bytearray()
        for index, value in enumerate(text):
            letter = value - 32 if value >= 97 else value
            key_letter = normalized_key[index % key_length]
            row = PORTA_SECOND_ROWS[(key_letter - 65) // 2]
            if letter < 78:
                output.append(row[letter - 65])
            else:
                output.append(65 + row.index(letter))
        return len(output), bytes(output)

    if algorithm == "fractionated_morse_cipher":
        max_input_length = 3 + MAX_FRACTIONATED_MORSE_TEXT_LENGTH + MAX_FRACTIONATED_MORSE_KEY_LENGTH
        if (not isinstance(values, list) or not 3 <= len(values) <= max_input_length
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mode, text_length, key_length = values[:3]
        if (mode not in (0, 1) or not 0 <= text_length <= MAX_FRACTIONATED_MORSE_TEXT_LENGTH
                or not 0 <= key_length <= MAX_FRACTIONATED_MORSE_KEY_LENGTH
                or len(values) != 3 + text_length + key_length):
            return -1, b""
        text = values[3:3 + text_length]
        key = values[3 + text_length:]
        if any(not (65 <= value <= 90 or 97 <= value <= 122) for value in key):
            return -1, b""
        keyed_alphabet = []
        for value in key:
            upper = value - 32 if value >= 97 else value
            if upper not in keyed_alphabet:
                keyed_alphabet.append(upper)
        keyed_alphabet.extend(value for value in range(65, 91) if value not in keyed_alphabet)

        if mode == 0:
            if any(value != 32 and not (65 <= value <= 90 or 97 <= value <= 122) for value in text):
                return -1, b""
            morse = bytearray()
            for index, value in enumerate(text):
                if index:
                    morse.append(ord("x"))
                if value == 32:
                    continue
                upper = value - 32 if value >= 97 else value
                morse.extend(FRACTIONATED_MORSE_CODES[upper - 65])
            morse.extend(b"x" * (3 - len(morse) % 3))
            output = bytearray()
            symbols = {ord("."): 0, ord("-"): 1, ord("x"): 2}
            for start in range(0, len(morse), 3):
                trigram = (symbols[morse[start]] * 9 + symbols[morse[start + 1]] * 3
                           + symbols[morse[start + 2]])
                if trigram < 26:
                    output.append(keyed_alphabet[trigram])
            return len(output), bytes(output)

        if any(not 65 <= value <= 90 for value in text):
            return -1, b""
        inverse_key = {letter: index for index, letter in enumerate(keyed_alphabet)}
        morse = bytearray()
        for value in text:
            trigram = FRACTIONATED_MORSE_TRIGRAMS[inverse_key[value]]
            morse.extend(trigram)
        decoded = bytearray()
        for code in bytes(morse).split(b"x"):
            if not code:
                decoded.append(32)
            elif code in FRACTIONATED_MORSE_REVERSE:
                decoded.append(FRACTIONATED_MORSE_REVERSE[code])
            else:
                return -1, b""
        output = bytes(decoded).strip()
        return len(output), output

    if algorithm == "beaufort_cipher":
        max_input_length = 3 + MAX_BEAUFORT_TEXT_LENGTH + MAX_BEAUFORT_KEY_LENGTH
        if (not isinstance(values, list) or not 3 <= len(values) <= max_input_length
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mode, text_length, key_length = values[:3]
        if (mode not in (0, 1) or not 0 <= text_length <= MAX_BEAUFORT_TEXT_LENGTH
                or not 0 <= key_length <= MAX_BEAUFORT_KEY_LENGTH
                or len(values) != 3 + text_length + key_length
                or (text_length == 0 and key_length != 0)
                or (text_length > 0 and not 1 <= key_length <= text_length)):
            return -1, b""
        text = values[3:3 + text_length]
        key = values[3 + text_length:]
        if any(value != 32 and not 65 <= value <= 90 for value in text):
            return -1, b""
        if any(not 65 <= value <= 90 for value in key):
            return -1, b""
        output = bytearray()
        key_index = 0
        for value in text:
            if value == 32:
                output.append(32)
                continue
            text_value = value - 65
            key_value = key[key_index % key_length] - 65
            mapped = (text_value - key_value) % 26 if mode == 0 else (text_value + key_value) % 26
            output.append(65 + mapped)
            key_index += 1
        return len(output), bytes(output)

    if algorithm == "vernam_cipher":
        if (not isinstance(values, list) or not 3 <= len(values) <= 3 + MAX_VERNAM_TEXT_LENGTH + MAX_VERNAM_KEY_LENGTH
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mode, text_length, key_length = values[:3]
        if (mode not in (0, 1) or not 0 <= text_length <= MAX_VERNAM_TEXT_LENGTH
                or not 1 <= key_length <= MAX_VERNAM_KEY_LENGTH
                or len(values) != 3 + text_length + key_length):
            return -1, b""
        text = values[3:3 + text_length]
        key = values[3 + text_length:]
        if any(not 65 <= value <= 90 for value in text + key):
            return -1, b""
        output = bytes(65 + ((value - 65 + (key[index % key_length] - 65) * (1 if mode == 0 else -1)) % 26)
                       for index, value in enumerate(text))
        return len(output), output

    if algorithm == "onepad_cipher":
        if (not isinstance(values, list) or not 2 <= len(values) <= 2050
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mode, text_length = values[:2]
        if (mode not in (0, 1) or not 0 <= text_length <= 1024
                or len(values) != 2 + 2 * text_length):
            return -1, b""
        text = values[2:2 + text_length]
        key = values[2 + text_length:]
        if any(not 1 <= value <= 300 for value in key):
            return -1, b""
        if mode == 0:
            if any(not 32 <= value <= 126 for value in text):
                return -1, b""
            output = b"".join(struct.pack("<q", (value + key[index]) * key[index])
                              for index, value in enumerate(text))
            return len(output), output
        plain = []
        for value, key_value in zip(text, key):
            key_square = key_value * key_value
            if value < key_square or (value - key_square) % key_value != 0:
                return -1, b""
            decoded = (value - key_square) // key_value
            if not 32 <= decoded <= 126:
                return -1, b""
            plain.append(decoded)
        output = bytes(plain)
        return len(output), output

    if algorithm == "one_time_pad_cipher":
        if (not isinstance(values, list) or not 2 <= len(values) <= 2050
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mode, text_length = values[:2]
        if (mode not in (0, 1) or not 0 <= text_length <= 1024
                or len(values) != 2 + 2 * text_length):
            return -1, b""
        text = values[2:2 + text_length]
        key = values[2 + text_length:]
        if any(not 0 <= value <= 255 for value in text + key):
            return -1, b""
        output = bytes(value ^ key_value for value, key_value in zip(text, key))
        return len(output), output

    if algorithm == "autokey_cipher":
        max_input_length = 4 + MAX_AUTOKEY_TEXT_LENGTH + MAX_AUTOKEY_KEY_LENGTH
        if (not isinstance(values, list) or not 4 <= len(values) <= max_input_length
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        mode, dialect, text_length, key_length = values[:4]
        if (mode not in (0, 1) or dialect not in (0, 1)
                or not 1 <= text_length <= MAX_AUTOKEY_TEXT_LENGTH
                or not 1 <= key_length <= MAX_AUTOKEY_KEY_LENGTH
                or len(values) != 4 + text_length + key_length):
            return -1, b""
        text = values[4:4 + text_length]
        key = values[4 + text_length:]
        if any(not (65 <= value <= 90 or 97 <= value <= 122) for value in text + key):
            return -1, b""
        if dialect == 1 and mode == 1 and any(65 <= value <= 90 for value in text):
            return -1, b""
        text = [value - 32 if value >= 97 else value for value in text]
        key = [value - 32 if value >= 97 else value for value in key]
        output = bytearray()
        for index, value in enumerate(text):
            key_value = key[index] if index < key_length else (
                text[index - key_length] if mode == 0 else output[index - key_length]
            )
            shift = key_value - 65
            letter = value - 65
            mapped = (letter + shift) % 26 if mode == 0 else (letter - shift) % 26
            output.append(65 + mapped)
        encoded = bytes(value + 32 if dialect == 1 else value for value in output)
        return len(encoded), encoded

    if algorithm == "digit_separation":
        if (len(values) != 2 or any(type(value) is not int for value in values)
                or not -(2**63) <= values[0] < 2**63 or values[1] not in (0, 1)):
            return -1, b""
        digits = [int(digit) for digit in str(abs(values[0]))]
        if values[1] == 0:
            digits.reverse()
        return len(digits), bytes(digits)

    if algorithm == "closest_pair_divide_and_conquer":
        max_points = 1024
        coordinate_limit = 1_000_000_000
        if (len(values) > 2 * max_points or len(values) % 2 != 0
                or any(type(value) is not int or not -coordinate_limit <= value <= coordinate_limit
                       for value in values)):
            return -1, b""
        points = list(zip(values[::2], values[1::2]))
        if len(points) < 2:
            return 0, b""
        best_distance = None
        best_pair = None
        for first in range(len(points)):
            for second in range(first + 1, len(points)):
                dx = points[first][0] - points[second][0]
                dy = points[first][1] - points[second][1]
                distance = dx * dx + dy * dy
                pair = (first, second)
                if (best_distance is None or distance < best_distance
                        or (distance == best_distance and pair < best_pair)):
                    best_distance, best_pair = distance, pair
        assert best_pair is not None
        return 2, best_pair[0].to_bytes(4, "little") + best_pair[1].to_bytes(4, "little")

    if algorithm == "convex_hull_graham_scan":
        max_points = 1024
        coordinate_limit = 1_000_000_000
        if (len(values) > 2 * max_points or len(values) % 2 != 0
                or any(type(value) is not int or not -(2**63) <= value < 2**63
                       or not -coordinate_limit <= value <= coordinate_limit for value in values)):
            return -1, b""
        first_index: dict[tuple[int, int], int] = {}
        for index, point in enumerate(zip(values[::2], values[1::2])):
            first_index.setdefault(point, index)
        points = sorted(first_index)
        if not points:
            return 0, b""
        if len(points) == 1:
            hull = points
        else:
            def turn(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
                return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

            all_collinear = all(turn(points[0], points[1], point) == 0 for point in points[2:])
            lower: list[tuple[int, int]] = []
            for point in points:
                while len(lower) >= 2 and turn(lower[-2], lower[-1], point) < 0:
                    lower.pop()
                lower.append(point)
            upper: list[tuple[int, int]] = []
            for point in reversed(points):
                while len(upper) >= 2 and turn(upper[-2], upper[-1], point) < 0:
                    upper.pop()
                upper.append(point)
            hull = list(dict.fromkeys(lower[:-1] + upper[:-1]))
            if all_collinear:
                pivot = min(points, key=lambda point: (point[1], point[0]))
                hull.sort(key=lambda point: (point[0] - pivot[0]) ** 2 + (point[1] - pivot[1]) ** 2)
            else:
                pivot = min(hull, key=lambda point: (point[1], point[0]))
                pivot_index = hull.index(pivot)
                hull = hull[pivot_index:] + hull[:pivot_index]
        output = b"".join(first_index[point].to_bytes(4, "little") for point in hull)
        return len(hull), output

    if algorithm == "convex_hull_quickhull":
        max_points = 1024
        coordinate_limit = 1_000_000_000
        if (len(values) > 2 * max_points or len(values) % 2 != 0
                or any(type(value) is not int or not -(2**63) <= value < 2**63
                       or not -coordinate_limit <= value <= coordinate_limit for value in values)):
            return -1, b""
        first_index: dict[tuple[int, int], int] = {}
        for index, point in enumerate(zip(values[::2], values[1::2])):
            first_index.setdefault(point, index)
        points = sorted(first_index)
        if len(points) <= 2:
            hull = points
        else:
            def turn(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
                return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

            lower: list[tuple[int, int]] = []
            for point in points:
                while len(lower) >= 2 and turn(lower[-2], lower[-1], point) <= 0:
                    lower.pop()
                lower.append(point)
            upper: list[tuple[int, int]] = []
            for point in reversed(points):
                while len(upper) >= 2 and turn(upper[-2], upper[-1], point) <= 0:
                    upper.pop()
                upper.append(point)
            hull = sorted(set(lower[:-1] + upper[:-1]))
        output = b"".join(first_index[point].to_bytes(4, "little") for point in hull)
        return len(hull), output

    if algorithm == "line_intersection":
        import struct

        coordinate_limit = 10_000
        if (len(values) != 9 or any(type(value) is not int or not -(2**63) <= value < 2**63
                                    for value in values)
                or values[8] not in (0, 1)
                or any(not -coordinate_limit <= value <= coordinate_limit for value in values[:8])):
            return -1, b""
        p1 = (values[0], values[1])
        p2 = (values[2], values[3])
        q1 = (values[4], values[5])
        q2 = (values[6], values[7])
        as_segments = values[8] == 1
        p_is_point, q_is_point = p1 == p2, q1 == q2
        if not as_segments and (p_is_point or q_is_point):
            return -1, b""

        def pack_point(point: tuple[float, float] | tuple[int, int]) -> tuple[int, bytes]:
            return 1, struct.pack("<dd", float(point[0]), float(point[1]))

        def on_segment(a: tuple[int, int], b: tuple[int, int], point: tuple[int, int]) -> bool:
            return ((b[0] - a[0]) * (point[1] - a[1]) - (b[1] - a[1]) * (point[0] - a[0]) == 0
                    and min(a[0], b[0]) <= point[0] <= max(a[0], b[0])
                    and min(a[1], b[1]) <= point[1] <= max(a[1], b[1]))

        if as_segments and p_is_point and q_is_point:
            return pack_point(p1) if p1 == q1 else (0, b"")
        if as_segments and p_is_point:
            return pack_point(p1) if on_segment(q1, q2, p1) else (0, b"")
        if as_segments and q_is_point:
            return pack_point(q1) if on_segment(p1, p2, q1) else (0, b"")
        x1, y1 = p1
        x2, y2 = p2
        x3, y3 = q1
        x4, y4 = q2
        denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
        if denominator == 0:
            return 0, b""
        determinant_p = x1 * y2 - y1 * x2
        determinant_q = x3 * y4 - y3 * x4
        numerator_x = determinant_p * (x3 - x4) - (x1 - x2) * determinant_q
        numerator_y = determinant_p * (y3 - y4) - (y1 - y2) * determinant_q
        if as_segments:
            positive_denominator = abs(denominator)
            positive_x = numerator_x if denominator > 0 else -numerator_x
            positive_y = numerator_y if denominator > 0 else -numerator_y
            min_x = max(min(x1, x2), min(x3, x4))
            max_x = min(max(x1, x2), max(x3, x4))
            min_y = max(min(y1, y2), min(y3, y4))
            max_y = min(max(y1, y2), max(y3, y4))
            if (positive_x < min_x * positive_denominator or positive_x > max_x * positive_denominator
                    or positive_y < min_y * positive_denominator or positive_y > max_y * positive_denominator):
                return 0, b""
            return pack_point((positive_x / positive_denominator, positive_y / positive_denominator))
        return pack_point((numerator_x / denominator, numerator_y / denominator))

    if algorithm == "line_segment_intersection":
        coordinate_limit = 10_000
        if (len(values) != 8 or any(type(value) is not int or not -(2**63) <= value < 2**63
                                    for value in values)
                or any(not -coordinate_limit <= value <= coordinate_limit for value in values)):
            return -1, b""
        a = (values[0], values[1])
        b = (values[2], values[3])
        c = (values[4], values[5])
        d = (values[6], values[7])

        def orientation(p: tuple[int, int], q: tuple[int, int], r: tuple[int, int]) -> int:
            return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])

        def on_segment(p: tuple[int, int], q: tuple[int, int], r: tuple[int, int]) -> bool:
            return (min(p[0], q[0]) <= r[0] <= max(p[0], q[0])
                    and min(p[1], q[1]) <= r[1] <= max(p[1], q[1]))

        ab_c, ab_d = orientation(a, b, c), orientation(a, b, d)
        cd_a, cd_b = orientation(c, d, a), orientation(c, d, b)
        proper_crossing = ((ab_c < 0 < ab_d or ab_d < 0 < ab_c)
                           and (cd_a < 0 < cd_b or cd_b < 0 < cd_a))
        touches_or_overlaps = ((ab_c == 0 and on_segment(a, b, c))
                               or (ab_d == 0 and on_segment(a, b, d))
                               or (cd_a == 0 and on_segment(c, d, a))
                               or (cd_b == 0 and on_segment(c, d, b)))
        return (1 if proper_crossing or touches_or_overlaps else 0), b""

    if algorithm == "check_polygon":
        if (len(values) < 3 or len(values) > 256
                or any(type(value) is not int or not -(2**63) <= value < 2**63
                       or not 1 <= value <= 1_000_000_000 for value in values)):
            return -1, b""
        total = sum(values)
        largest = max(values)
        return (1 if largest < total - largest else 0), b""

    if algorithm == "bresenham_line":
        if (len(values) != 4
                or any(type(value) is not int or not -(2**63) <= value < 2**63
                       for value in values)):
            return -1, b""
        x0, y0, x1, y1 = values
        if any(not -1_000_000 <= coordinate <= 1_000_000
               for coordinate in values):
            return -1, b""
        dx = abs(x1 - x0)
        abs_dy = abs(y1 - y0)
        if max(dx, abs_dy) > 4_096:
            return -1, b""
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        dy = -abs_dy
        error = dx + dy
        x, y = x0, y0
        output = bytearray()
        while True:
            output.extend(struct.pack("<ii", x, y))
            if x == x1 and y == y1:
                break
            doubled_error = 2 * error
            if doubled_error > dy:
                error += dy
                x += sx
            if doubled_error < dx:
                error += dx
                y += sy
        encoded = bytes(output)
        return len(encoded), encoded

    if algorithm == "bresenhams_line":
        if (len(values) != 4
                or any(type(value) is not int or not -(2**63) <= value < 2**63
                       for value in values)):
            return -1, b""
        x0, y0, x1, y1 = values
        if any(not -1_000_000 <= coordinate <= 1_000_000
               for coordinate in values):
            return -1, b""
        dx = abs(x1 - x0)
        abs_dy = abs(y1 - y0)
        if max(dx, abs_dy) > 4_096:
            return -1, b""
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        dy = -abs_dy
        error = dx + dy
        x, y = x0, y0
        output = bytearray()
        while True:
            output.extend(struct.pack("<ii", x, y))
            if x == x1 and y == y1:
                break
            doubled_error = 2 * error
            if doubled_error >= dy:
                error += dy
                x += sx
            if doubled_error <= dx:
                error += dx
                y += sy
        encoded = bytes(output)
        return len(encoded), encoded

    if algorithm == "counting_sort_string":
        if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
                or any(type(value) is not int or not -(2**63) <= value < 2**63
                       for value in values)):
            return -1, b""
        count = values[0]
        if count < 0 or count > 4095 or len(values) != count + 1:
            return -1, b""
        if any(not 33 <= value <= 126 for value in values[1:]):
            return -1, b""
        frequencies = [0] * 256
        for value in values[1:]:
            frequencies[value] += 1
        for value in range(1, 256):
            frequencies[value] += frequencies[value - 1]
        output = bytearray(count)
        for value in reversed(values[1:]):
            frequencies[value] -= 1
            output[frequencies[value]] = value
        encoded = bytes(output)
        return len(encoded), encoded

    if algorithm == "ear_clipping_polygon_triangulation":
        if (len(values) < 6 or len(values) > 128 or len(values) % 2 != 0
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
                or any(not -10_000 <= value <= 10_000 for value in values)):
            return -1, b""
        points = list(zip(values[::2], values[1::2]))
        count = len(points)
        if len(set(points)) != count:
            return -1, b""

        def cross(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
            return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

        def on_segment(a: tuple[int, int], b: tuple[int, int], p: tuple[int, int]) -> bool:
            return (cross(a, b, p) == 0 and min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
                    and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))

        def intersects(a: tuple[int, int], b: tuple[int, int],
                       c: tuple[int, int], d: tuple[int, int]) -> bool:
            ab_c, ab_d = cross(a, b, c), cross(a, b, d)
            cd_a, cd_b = cross(c, d, a), cross(c, d, b)
            if ((ab_c > 0 > ab_d or ab_c < 0 < ab_d)
                    and (cd_a > 0 > cd_b or cd_a < 0 < cd_b)):
                return True
            return ((ab_c == 0 and on_segment(a, b, c)) or (ab_d == 0 and on_segment(a, b, d))
                    or (cd_a == 0 and on_segment(c, d, a)) or (cd_b == 0 and on_segment(c, d, b)))

        area_twice = sum(points[i][0] * points[(i + 1) % count][1]
                         - points[i][1] * points[(i + 1) % count][0] for i in range(count))
        if area_twice == 0 or any(cross(points[i], points[(i + 1) % count], points[(i + 2) % count]) == 0
                                  for i in range(count)):
            return -1, b""
        for first in range(count):
            for second in range(first + 1, count):
                if second == first + 1 or (first == 0 and second == count - 1):
                    continue
                if intersects(points[first], points[(first + 1) % count],
                              points[second], points[(second + 1) % count]):
                    return -1, b""

        winding = 1 if area_twice > 0 else -1
        live = [True] * count
        triangles: list[int] = []
        remaining = count
        while remaining > 3:
            clipped = False
            for current in range(count):
                if not live[current]:
                    continue
                previous = (current - 1) % count
                while not live[previous]:
                    previous = (previous - 1) % count
                following = (current + 1) % count
                while not live[following]:
                    following = (following + 1) % count
                if cross(points[previous], points[current], points[following]) * winding <= 0:
                    continue
                blocked = False
                for test in range(count):
                    if not live[test] or test in (previous, current, following):
                        continue
                    if (cross(points[previous], points[current], points[test]) * winding >= 0
                            and cross(points[current], points[following], points[test]) * winding >= 0
                            and cross(points[following], points[previous], points[test]) * winding >= 0):
                        blocked = True
                        break
                if blocked:
                    continue
                triangles.extend((previous, current, following))
                live[current] = False
                remaining -= 1
                clipped = True
                break
            if not clipped:
                return -1, b""

        first = next(index for index, is_live in enumerate(live) if is_live)
        second = (first + 1) % count
        while not live[second]:
            second = (second + 1) % count
        third = (second + 1) % count
        while not live[third]:
            third = (third + 1) % count
        triangles.extend((first, second, third))
        output = b"".join(index.to_bytes(4, "little") for index in triangles)
        return count - 2, output

    if algorithm == "midpoint_circle":
        if (len(values) != 3 or any(type(value) is not int or not -(2**63) <= value < 2**63
                                    for value in values)
                or not -10_000 <= values[0] <= 10_000
                or not -10_000 <= values[1] <= 10_000
                or not 0 <= values[2] <= 1000):
            return -1, b""
        center_x, center_y, radius = values
        points: list[tuple[int, int]] = []
        if radius == 0:
            points.append((center_x, center_y))
        else:
            x, y, decision = radius, 0, 1 - radius

            def append_symmetric_points(px: int, py: int) -> None:
                points.extend(((center_x + px, center_y + py), (center_x - px, center_y + py),
                               (center_x + px, center_y - py), (center_x - px, center_y - py),
                               (center_x + py, center_y + px), (center_x - py, center_y + px),
                               (center_x + py, center_y - px), (center_x - py, center_y - px)))

            append_symmetric_points(x, y)
            while x > y:
                y += 1
                if decision <= 0:
                    decision += 2 * y + 1
                else:
                    x -= 1
                    decision += 2 * y - 2 * x + 1
                append_symmetric_points(x, y)
        output = b"".join(struct.pack("<ii", x, y) for x, y in points)
        return len(points), output

    if algorithm == "midpoint_ellipse":
        if (len(values) != 4 or any(type(value) is not int or not -(2**63) <= value < 2**63
                                    for value in values)
                or not -10_000 <= values[0] <= 10_000
                or not -10_000 <= values[1] <= 10_000
                or not 0 <= values[2] <= 100 or not 0 <= values[3] <= 100):
            return -1, b""
        center_x, center_y, a, b = values
        points: list[tuple[int, int]] = []
        if a == 0 and b == 0:
            points.append((center_x, center_y))
        elif a == 0:
            points.extend((center_x, y) for y in range(center_y - b, center_y + b + 1))
        elif b == 0:
            points.extend((x, center_y) for x in range(center_x - a, center_x + a + 1))
        else:
            x, y = 0, b
            a_squared, b_squared = a * a, b * b
            d1 = float(b_squared) - float(a_squared * b) + 0.25 * float(a_squared)
            dx = 2.0 * float(b_squared) * float(x)
            dy = 2.0 * float(a_squared) * float(y)

            def append_symmetric_points(px: int, py: int) -> None:
                points.extend(((center_x + px, center_y + py), (center_x - px, center_y + py),
                               (center_x + px, center_y - py), (center_x - px, center_y - py)))

            while dx < dy:
                append_symmetric_points(x, y)
                if d1 < 0.0:
                    x += 1
                    dx += 2.0 * float(b_squared)
                    d1 += dx + float(b_squared)
                else:
                    x += 1
                    y -= 1
                    dx += 2.0 * float(b_squared)
                    dy -= 2.0 * float(a_squared)
                    d1 += dx - dy + float(b_squared)

            d2 = (float(b_squared) * (float(x) + 0.5) * (float(x) + 0.5)
                  + float(a_squared * (y - 1) * (y - 1)) - float(a_squared * b_squared))
            while y >= 0:
                append_symmetric_points(x, y)
                if d2 > 0.0:
                    y -= 1
                    dy -= 2.0 * float(a_squared)
                    d2 += float(a_squared) - dy
                else:
                    y -= 1
                    x += 1
                    dx += 2.0 * float(b_squared)
                    dy -= 2.0 * float(a_squared)
                    d2 += dx - dy + float(a_squared)
        output = b"".join(struct.pack("<ii", x, y) for x, y in points)
        return len(points), output

    if algorithm == "smallest_circle":
        import math

        if (len(values) < 2 or len(values) > 24 or len(values) % 2 != 0
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
                or any(not -100 <= value <= 100 for value in values)):
            return -1, b""
        points = list(zip(values[::2], values[1::2]))
        best: tuple[float, float, float] | None = None

        def contains_all(circle: tuple[float, float, float]) -> bool:
            cx, cy, radius = circle
            radius_squared = radius * radius
            return all((cx - x) ** 2 + (cy - y) ** 2 <= radius_squared + 1e-12 for x, y in points)

        def consider(circle: tuple[float, float, float]) -> None:
            nonlocal best
            if contains_all(circle) and (best is None or circle[2] <= best[2]):
                best = circle

        if len(points) == 1:
            best = (float(points[0][0]), float(points[0][1]), 0.0)
        for i in range(len(points)):
            for j in range(i + 1, len(points)):
                for k in range(j + 1, len(points)):
                    xi, yi = points[i]
                    xj, yj = points[j]
                    xk, yk = points[k]
                    denominator = 2 * (xi * (yj - yk) + xj * (yk - yi) + xk * (yi - yj))
                    if denominator == 0:
                        continue
                    norm_i, norm_j, norm_k = xi * xi + yi * yi, xj * xj + yj * yj, xk * xk + yk * yk
                    numerator_x = norm_i * (yj - yk) + norm_j * (yk - yi) + norm_k * (yi - yj)
                    numerator_y = norm_i * (xk - xj) + norm_j * (xi - xk) + norm_k * (xj - xi)
                    cx, cy = numerator_x / denominator, numerator_y / denominator
                    radius = math.sqrt((cx - xi) ** 2 + (cy - yi) ** 2)
                    consider((cx, cy, radius))
        for i in range(len(points)):
            for j in range(i + 1, len(points)):
                cx = (points[i][0] + points[j][0]) / 2.0
                cy = (points[i][1] + points[j][1]) / 2.0
                radius = math.sqrt((cx - points[i][0]) ** 2 + (cy - points[i][1]) ** 2)
                consider((cx, cy, radius))
        if best is None:
            return -1, b""
        return 1, struct.pack("<ddd", *best)

    if algorithm in {"lowest_common_ancestor_binary_lifting", "lowest_common_ancestor_tarjan"}:
        return lowest_common_ancestor_batch_output(values)
    if algorithm == "articulation_points":
        return articulation_points_output(values)
    if algorithm == "bridges":
        return bridges_output(values)
    if algorithm == "kosaraju":
        return kosaraju_output(values)
    if algorithm == "tarjan_scc":
        return tarjan_scc_output(values)
    if algorithm == "bfs_queue":
        return bfs_queue_output(values)
    if algorithm == "zero_one_bfs":
        return zero_one_bfs_output(values)
    if algorithm == "gray_code":
        if len(values) != 1 or type(values[0]) is not int or not 0 <= values[0] <= 13:
            return -1, b""
        bit_count = values[0]
        if bit_count == 0:
            return 0, b""
        output = b"".join((index ^ (index >> 1)).to_bytes(4, "little")
                           for index in range(1 << bit_count))
        return 1 << bit_count, output

    if algorithm == "binary_to_gray":
        if (not 1 <= len(values) <= MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int or value not in (ord("0"), ord("1"))
                       for value in values)):
            return -1, b""
        output = bytearray(len(values))
        for index, value in enumerate(values):
            current = value - ord("0")
            previous = 0 if index == 0 else values[index - 1] - ord("0")
            output[index] = ord("0") + (current ^ previous)
        return len(output), bytes(output)

    if algorithm == "z_algorithm":
        if (not isinstance(values, list) or not 1 <= len(values) <= 2048
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        count = values[0]
        if not 0 <= count <= 2047 or len(values) != count + 1:
            return -1, b""
        sequence = values[1:]
        z_values = [0] * count
        for index in range(1, count):
            matched = 0
            while (index + matched < count
                   and sequence[matched] == sequence[index + matched]):
                matched += 1
            z_values[index] = matched
        encoded = bytearray()
        for value in z_values:
            encoded.extend(value.to_bytes(4, "little"))
        return count, bytes(encoded)

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

    if algorithm == "adam":
        import struct

        input_scale = 1_000_000_000
        output_scale = 1_000_000
        max_steps = 256
        max_parameters = 16
        if (not isinstance(values, list) or not 9 <= len(values) <= 7 + max_parameters + max_steps * max_parameters
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        steps, parameter_count, learning_rate_value, beta1_value, beta2_value, epsilon_value, weight_decay_value = values[:7]
        if (not 1 <= steps <= max_steps or not 1 <= parameter_count <= max_parameters
                or len(values) != 7 + parameter_count + steps * parameter_count
                or not 1 <= learning_rate_value <= input_scale
                or not 0 <= beta1_value < input_scale or not 0 <= beta2_value < input_scale
                or not 1 <= epsilon_value <= 10_000_000 or not 0 <= weight_decay_value <= 100_000_000):
            return -1, b""
        parameter_values = values[7:7 + parameter_count]
        gradient_values = values[7 + parameter_count:]
        if (any(not -1_000_000_000_000_000 <= value <= 1_000_000_000_000_000 for value in parameter_values)
                or any(not -1_000_000_000_000 <= value <= 1_000_000_000_000 for value in gradient_values)):
            return -1, b""

        learning_rate = learning_rate_value / input_scale
        beta1 = beta1_value / input_scale
        beta2 = beta2_value / input_scale
        epsilon = epsilon_value / input_scale
        weight_decay = weight_decay_value / input_scale
        parameters = [value / input_scale for value in parameter_values]
        first_moment = [0.0] * parameter_count
        second_moment = [0.0] * parameter_count
        beta1_power = 1.0
        beta2_power = 1.0

        def adam_sqrt(value: float) -> float:
            if value <= 0.0:
                return 0.0
            root = value if value > 1.0 else 1.0
            for _ in range(80):
                root = 0.5 * (root + value / root)
            return root

        output_values = []
        for step in range(steps):
            beta1_power *= beta1
            beta2_power *= beta2
            for index in range(parameter_count):
                gradient = gradient_values[step * parameter_count + index] / input_scale
                first_moment[index] = beta1 * first_moment[index] + (1.0 - beta1) * gradient
                second_moment[index] = beta2 * second_moment[index] + (1.0 - beta2) * (gradient * gradient)
                corrected_first = first_moment[index] / (1.0 - beta1_power)
                corrected_second = second_moment[index] / (1.0 - beta2_power)
                updated = (parameters[index] - learning_rate * corrected_first /
                           (adam_sqrt(corrected_second) + epsilon) -
                           learning_rate * weight_decay * parameters[index])
                parameters[index] = updated
                output_values.append(math.trunc(updated * output_scale))
        return len(output_values), struct.pack("<" + "q" * len(output_values), *output_values)

    if algorithm == "adwin":
        import struct

        input_scale = 1_000_000_000
        max_samples = 256
        max_levels = 16
        max_buckets = 5
        bucket_capacity = max_buckets + 1
        min_subwindow = 5
        if (not isinstance(values, list) or not 3 <= len(values) <= 2 + max_samples
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        sample_count, delta_value = values[:2]
        samples = values[2:]
        if (not 1 <= sample_count <= max_samples or len(samples) != sample_count
                or not 1 <= delta_value <= 100_000_000
                or any(not -input_scale <= value <= input_scale for value in samples)):
            return -1, b""

        def adwin_sqrt(value: float) -> float:
            if value <= 0.0:
                return 0.0
            root = value if value > 1.0 else 1.0
            for _ in range(80):
                root = 0.5 * (root + value / root)
            return root

        def adwin_ln(input_value: float) -> float:
            value = input_value
            exponent = 0
            while value >= 2.0:
                value *= 0.5
                exponent += 1
            ratio = (value - 1.0) / (value + 1.0)
            square = ratio * ratio
            term = ratio
            total = 0.0
            for iteration in range(40):
                total += term / (2 * iteration + 1)
                term *= square
            return 2.0 * total + exponent * 0.693147180559945309417232121458176568

        sizes = [0] * max_levels
        totals = [[0.0] * bucket_capacity for _ in range(max_levels)]
        variances = [[0.0] * bucket_capacity for _ in range(max_levels)]
        width = 0
        total = 0.0
        variance = 0.0
        delta = delta_value / input_scale
        output_values = []

        for raw_value in samples:
            value = raw_value / input_scale
            width += 1
            totals[0][sizes[0]] = value
            variances[0][sizes[0]] = 0.0
            sizes[0] += 1
            if width > 1:
                deviation = value - total / (width - 1)
                variance += (width - 1) * deviation * deviation / width
            total += value

            for level in range(max_levels - 1):
                if sizes[level] <= max_buckets:
                    break
                bucket_size = float(1 << level)
                first_mean = totals[level][0] / bucket_size
                second_mean = totals[level][1] / bucket_size
                difference = first_mean - second_mean
                merged_variance = (variances[level][0] + variances[level][1] +
                                   bucket_size * bucket_size * difference * difference /
                                   (bucket_size + bucket_size))
                next_slot = sizes[level + 1]
                totals[level + 1][next_slot] = totals[level][0] + totals[level][1]
                variances[level + 1][next_slot] = merged_variance
                sizes[level + 1] += 1
                for bucket in range(2, sizes[level]):
                    totals[level][bucket - 2] = totals[level][bucket]
                    variances[level][bucket - 2] = variances[level][bucket]
                sizes[level] -= 2

            changed = False
            searching = True
            while searching and width >= 2 * min_subwindow:
                searching = False
                stop = False
                old_width = 0
                old_total = 0.0
                for level in range(max_levels - 1, -1, -1):
                    for bucket in range(sizes[level]):
                        if level == 0 and bucket == sizes[level] - 1:
                            stop = True
                            break
                        old_width += 1 << level
                        old_total += totals[level][bucket]
                        recent_width = width - old_width
                        recent_total = total - old_total
                        if recent_width < min_subwindow:
                            stop = True
                            break
                        if old_width >= min_subwindow:
                            harmonic = (1.0 / (old_width - min_subwindow + 1) +
                                        1.0 / (recent_width - min_subwindow + 1))
                            confidence = adwin_ln(2.0 * adwin_ln(float(width)) / delta)
                            window_variance = variance / width
                            epsilon = (adwin_sqrt(2.0 * harmonic * window_variance * confidence) +
                                       2.0 / 3.0 * confidence * harmonic)
                            difference = old_total / old_width - recent_total / recent_width
                            if abs(difference) > epsilon:
                                changed = True
                                searching = True
                                oldest_level = max(level for level in range(max_levels) if sizes[level] > 0)
                                bucket_size = 1 << oldest_level
                                bucket_total = totals[oldest_level][0]
                                width -= bucket_size
                                total -= bucket_total
                                if width > 0:
                                    bucket_mean = bucket_total / bucket_size
                                    drop_difference = bucket_mean - total / width
                                    variance -= (variances[oldest_level][0] + bucket_size * width *
                                                 drop_difference * drop_difference / (bucket_size + width))
                                else:
                                    variance = 0.0
                                if variance < 0.0:
                                    variance = 0.0
                                for index in range(1, sizes[oldest_level]):
                                    totals[oldest_level][index - 1] = totals[oldest_level][index]
                                    variances[oldest_level][index - 1] = variances[oldest_level][index]
                                sizes[oldest_level] -= 1
                                stop = True
                                break
                    if stop:
                        break

            output_values.extend((int(changed), width))
        output = struct.pack("<" + "q" * len(output_values), *output_values)
        return len(output_values), output

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

    if algorithm == "naive_shuffler":
        if (len(values) < 2 or len(values) > MAX_NAIVE_SHUFFLER_INPUT_LENGTH
                or any(type(value) is not int for value in values)):
            return -1, b""
        seed, count = values[:2]
        modulus = 2_147_483_647
        period = modulus - 1
        if not 0 <= seed < period or not 0 <= count <= 256 or len(values) != count + 2:
            return -1, b""
        items = values[2:]
        if any(not 0 <= value <= 255 for value in items):
            return -1, b""
        state = seed + 1
        for index in range(count):
            bound = count
            limit = period - period % bound
            while True:
                state = state * 48_271 % modulus
                sample = state - 1
                if sample < limit:
                    other = sample % bound
                    items[index], items[other] = items[other], items[index]
                    break
        return count, bytes(items)

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

    if algorithm in {"sudoku_solver", "sudoku_solver_mrv"}:
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

    if algorithm == "hamming_numbers":
        import struct

        if (not isinstance(values, list) or len(values) != 1
                or type(values[0]) is not int or not 1 <= values[0] <= 32):
            return -1, b""
        count = values[0]
        numbers = []
        candidate = 1
        while len(numbers) < count:
            remaining = candidate
            for factor in (2, 3, 5):
                while remaining % factor == 0:
                    remaining //= factor
            if remaining == 1:
                numbers.append(candidate)
            candidate += 1
        return count, struct.pack("<" + "q" * count, *numbers)

    if algorithm == "binary_prime_constant_sequence":
        if (not isinstance(values, list) or len(values) != 1
                or type(values[0]) is not int or not 0 <= values[0] <= 4096):
            return -1, b""
        count = values[0]

        def is_prime(candidate: int) -> bool:
            if candidate < 2:
                return False
            divisor = 2
            while divisor <= candidate // divisor:
                if candidate % divisor == 0:
                    return False
                divisor += 1
            return True

        output = bytes(1 if is_prime(index) else 0 for index in range(1, count + 1))
        return count, output

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

    if algorithm == "gronsfeld_cipher":
        max_input_length = 1 + MAX_GRONSFELD_TEXT_LENGTH + MAX_GRONSFELD_KEY_LENGTH
        if (not isinstance(values, list) or not 1 <= len(values) <= max_input_length
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            return -1, b""
        try:
            separator = values.index(0)
        except ValueError:
            return -1, b""
        message, key = values[:separator], values[separator + 1:]
        if (len(message) > MAX_GRONSFELD_TEXT_LENGTH or len(key) > MAX_GRONSFELD_KEY_LENGTH
                or any(not 1 <= value <= 127 for value in message)
                or any(not 48 <= value <= 57 for value in key)):
            return -1, b""
        if not key and any(65 <= value <= 90 or 97 <= value <= 122 for value in message):
            return -1, b""
        output = bytearray()
        for index, value in enumerate(message):
            upper = value - 32 if 97 <= value <= 122 else value
            if 65 <= upper <= 90:
                shift = key[index % len(key)] - 48
                upper = 65 + (upper - 65 + shift) % 26
            output.append(upper)
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

    if algorithm == "upper":
        if (len(values) > 256
                or any(type(value) is not int or not 0 <= value <= 127
                       or value in range(9, 14) or value == 32 for value in values)):
            return -1, b""
        output = bytes(value - 32 if 97 <= value <= 122 else value for value in values)
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

    if algorithm == "bloom_filter":
        if (len(values) > 256 or len(values) % 2 != 0
                or any(type(value) is not int or not -(2**63) <= value < 2**63
                       for value in values)):
            return -1, b""
        operations = []
        for index in range(0, len(values), 2):
            operation, key = values[index:index + 2]
            if operation not in (1, 2) or not 0 <= key <= 1_000_000_000:
                return -1, b""
            operations.append((operation, key))
        bits = 0
        output = bytearray()
        for operation, key in operations:
            first = (key * 17 + 3) % 64
            second = (key * 31 + 7) % 64
            first_mask = 1 << first
            second_mask = 1 << second
            if operation == 1:
                bits |= first_mask | second_mask
            else:
                output.append(int((bits & first_mask) != 0 and (bits & second_mask) != 0))
        return len(output), bytes(output)

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

    if algorithm == "reverse_complement":
        if (len(values) > MAX_REVERSE_COMPLEMENT_LENGTH
                or any(type(value) is not int or value not in (65, 67, 71, 84) for value in values)):
            return -1, b""
        complement = {65: 84, 84: 65, 67: 71, 71: 67}
        output = bytes(complement[value] for value in reversed(values))
        return len(output), output

    if algorithm == "word_count_julia":
        if (not isinstance(values, list) or len(values) > MAX_WORD_COUNT_JULIA_LENGTH
                or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
            return -1, b""
        text = bytes(value + 32 if 65 <= value <= 90 else value for value in values)
        words: list[bytes] = []
        index = 0
        while index < len(text):
            if not (text[index] == 95 or 48 <= text[index] <= 57
                    or 97 <= text[index] <= 122):
                index += 1
                continue
            start = index
            while (index < len(text) and (text[index] == 95 or 48 <= text[index] <= 57
                                          or 97 <= text[index] <= 122)):
                index += 1
            token = bytearray(text[start:index])
            if (index + 1 < len(text) and text[index] == 39
                    and (text[index + 1] == 95 or 48 <= text[index + 1] <= 57
                         or 97 <= text[index + 1] <= 122)):
                token.extend(text[index:index + 2])
                index += 2
            words.append(bytes(token))
        counts: dict[bytes, int] = {}
        for word in words:
            counts[word] = counts.get(word, 0) + 1
        output = b"".join(word + b"=" + str(count).encode("ascii") + b"\n"
                          for word, count in sorted(counts.items()))
        return len(output), output

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

    if algorithm == "harshad_numbers_in_base":
        if (len(values) != 2 or any(type(value) is not int for value in values)):
            return -1, b""
        limit, base = values
        if base < 2 or base > 36 or limit > 10_000:
            return -1, b""
        output = bytearray()
        if limit > 1:
            alphabet = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            for number in range(1, limit):
                remaining = number
                digit_sum = 0
                while remaining:
                    digit_sum += remaining % base
                    remaining //= base
                if number % digit_sum != 0:
                    continue
                digits = bytearray()
                remaining = number
                while remaining:
                    digits.append(alphabet[remaining % base])
                    remaining //= base
                output.extend(reversed(digits))
                output.append(0)
        return len(output), bytes(output)

    if algorithm == "wiggle_sort_strict":
        import struct

        if (len(values) > MAX_WAVE_SORT_INPUT_LENGTH
                or any(type(value) is not int or not -(2**31) <= value < 2**31 for value in values)):
            return -1, b""
        if not values:
            return 0, b""
        ordered = list(values)
        low = 0
        high = len(ordered) - 1
        target = len(ordered) // 2
        while low < high:
            left = low
            right = high
            pivot = ordered[(left + right + 1) // 2]
            while left <= right:
                while left <= right and ordered[left] < pivot:
                    left += 1
                while left <= right and ordered[right] > pivot:
                    right -= 1
                if left <= right:
                    ordered[left], ordered[right] = ordered[right], ordered[left]
                    left += 1
                    right -= 1
            if target <= right:
                high = right
            elif target >= left:
                low = left
            else:
                break
        median = ordered[target]
        median_count = sum(value == median for value in ordered)
        maximum_medians = (len(ordered) + 1) // 2
        if (median_count > maximum_medians
                or (len(ordered) % 2 == 1 and median_count == maximum_medians
                    and min(ordered) != median)):
            return -1, b""
        left = 0
        scan = 0
        right = len(ordered) - 1
        modulus = len(ordered) + 1 - (len(ordered) % 2)
        while scan <= right:
            mapped_scan = (2 * scan + 1) % modulus
            if ordered[mapped_scan] > median:
                mapped_left = (2 * left + 1) % modulus
                ordered[mapped_scan], ordered[mapped_left] = ordered[mapped_left], ordered[mapped_scan]
                left += 1
                scan += 1
            elif ordered[mapped_scan] < median:
                mapped_right = (2 * right + 1) % modulus
                ordered[mapped_scan], ordered[mapped_right] = ordered[mapped_right], ordered[mapped_scan]
                right -= 1
            else:
                scan += 1
        output = struct.pack("<" + "i" * len(ordered), *ordered)
        return len(ordered), output

    if algorithm == "simplified_wiggle_sort":
        if (len(values) > MAX_WAVE_SORT_INPUT_LENGTH
                or any(type(value) is not int or not -(2**31) <= value < 2**31 for value in values)):
            return -1, b""
        if not values:
            return 0, b""
        ordered = list(values)
        low = 0
        high = len(ordered) - 1
        target = len(ordered) // 2
        while low < high:
            left = low
            right = high
            pivot = ordered[(left + right + 1) // 2]
            while left <= right:
                while left <= right and ordered[left] < pivot:
                    left += 1
                while left <= right and ordered[right] > pivot:
                    right -= 1
                if left <= right:
                    ordered[left], ordered[right] = ordered[right], ordered[left]
                    left += 1
                    right -= 1
            if target <= right:
                high = right
            elif target >= left:
                low = left
            else:
                break
        median = ordered[target]
        result = [0] * len(ordered)
        smaller = 0
        greater = len(ordered) - 1 - (len(ordered) % 2)
        for value in ordered:
            if value > median:
                result[greater] = value
                greater -= 2
            elif smaller < len(ordered):
                result[smaller] = value
                smaller += 2
            else:
                result[greater] = value
                greater -= 2
        output = struct.pack("<" + "i" * len(result), *result)
        return len(result), output

    if algorithm in {"wave_sort", "wave_sort_greedy", "wiggle_sort"}:
        if (len(values) > MAX_WAVE_SORT_INPUT_LENGTH
                or any(type(value) is not int or not -(2**31) <= value < 2**31 for value in values)):
            return -1, b""
        ordered = list(values)
        if algorithm == "wave_sort":
            ordered.sort()
            for index in range(0, len(ordered) - 1, 2):
                ordered[index], ordered[index + 1] = ordered[index + 1], ordered[index]
        elif algorithm == "wave_sort_greedy":
            for index in range(0, len(ordered), 2):
                if index > 0 and ordered[index] < ordered[index - 1]:
                    ordered[index], ordered[index - 1] = ordered[index - 1], ordered[index]
                if index + 1 < len(ordered) and ordered[index] < ordered[index + 1]:
                    ordered[index], ordered[index + 1] = ordered[index + 1], ordered[index]
        else:
            for index in range(1, len(ordered)):
                if ((index % 2 == 1 and ordered[index - 1] > ordered[index])
                        or (index % 2 == 0 and ordered[index - 1] < ordered[index])):
                    ordered[index - 1], ordered[index] = ordered[index], ordered[index - 1]
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

    if algorithm == "manacher":
        if (not isinstance(values, list) or not 1 <= len(values) <= 1000
                or any(type(value) is not int or
                       not (48 <= value <= 57 or 65 <= value <= 90 or 97 <= value <= 122)
                       for value in values)):
            return -1, b""
        best_start = 0
        best_length = 0
        for center in range(len(values)):
            left = center
            right = center
            while left >= 0 and right < len(values) and values[left] == values[right]:
                candidate_length = right - left + 1
                if (candidate_length > best_length or
                        (candidate_length == best_length and left < best_start)):
                    best_start = left
                    best_length = candidate_length
                left -= 1
                right += 1

            left = center
            right = center + 1
            while left >= 0 and right < len(values) and values[left] == values[right]:
                candidate_length = right - left + 1
                if (candidate_length > best_length or
                        (candidate_length == best_length and left < best_start)):
                    best_start = left
                    best_length = candidate_length
                left -= 1
                right += 1
        return best_length, bytes(values[best_start:best_start + best_length])

    if algorithm == "duval_algorithm":
        if (not isinstance(values, list) or len(values) > 4096
                or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
            return -1, b""
        output = bytearray()
        start = 0
        while start < len(values):
            end = start + 1
            repeat = start
            while end < len(values) and values[repeat] <= values[end]:
                if values[repeat] < values[end]:
                    repeat = start
                else:
                    repeat += 1
                end += 1
            factor_length = end - repeat
            while start <= repeat:
                output.extend(struct.pack("<I", factor_length))
                start += factor_length
        return len(output) // 4, bytes(output)

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

    if algorithm == "topological":
        if (not 1 <= len(values) <= MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= 64
                or (len(values) - 1) % 2 != 0):
            return -2, b""
        vertices = values[0]
        dependencies = [0] * vertices
        adjacency = [[False] * vertices for _ in range(vertices)]
        for offset in range(1, len(values), 2):
            origin, destination = values[offset:offset + 2]
            if not 0 <= origin < vertices or not 0 <= destination < vertices:
                return -2, b""
            dependencies[destination] += 1
            adjacency[origin][destination] = True

        answer = []
        for root in range(vertices):
            if dependencies[root] != 0:
                continue
            stack = [root]
            route = []
            while stack:
                origin = stack.pop()
                route.append(origin)
                for destination in range(vertices):
                    if adjacency[origin][destination] and destination not in stack:
                        stack.append(destination)
                    adjacency[origin][destination] = False
                    adjacency[destination][origin] = False
                # The source calls its helper with end == vertices, outside the
                # valid vertex IDs, so each route drains completely.
            answer.extend(route)
        return len(answer), bytes(answer)

    if algorithm in {"topological_sort", "topological_sort_dfs"}:
        maximum_vertices = 40 if algorithm == "topological_sort_dfs" else 64
        if (not 1 <= len(values) <= MAX_SMALL_INPUT_LENGTH
                or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= maximum_vertices
                or (len(values) - 1) % 2 != 0):
            return -2, b""
        vertices = values[0]
        adjacency = [set() for _ in range(vertices)]
        for offset in range(1, len(values), 2):
            origin, destination = values[offset:offset + 2]
            if not 0 <= origin < vertices or not 0 <= destination < vertices:
                return -2, b""
            adjacency[origin].add(destination)
        if algorithm == "topological_sort_dfs":
            state = [0] * vertices
            postorder = []
            for root in range(vertices):
                if state[root] != 0:
                    continue
                state[root] = 1
                frames = [(root, iter(sorted(adjacency[root])))]
                while frames:
                    origin, neighbors = frames[-1]
                    destination = next(neighbors, None)
                    if destination is None:
                        state[origin] = 2
                        postorder.append(origin)
                        frames.pop()
                    elif state[destination] == 1:
                        return -1, b""
                    elif state[destination] == 0:
                        state[destination] = 1
                        frames.append((destination, iter(sorted(adjacency[destination]))))
            order = list(reversed(postorder))
        else:
            indegree = [0] * vertices
            for origin in range(vertices):
                for destination in adjacency[origin]:
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

    if algorithm == "boyer_moore_ag":
        if (not 2 <= len(values) <= 512
                or any(type(value) is not int for value in values)):
            return -1, b""
        text_length, pattern_length = values[:2]
        if (not 0 <= text_length <= 255 or not 1 <= pattern_length <= 255
                or len(values) != 2 + text_length + pattern_length):
            return -1, b""
        text = values[2:2 + text_length]
        pattern = values[2 + text_length:]
        if any(not 0 <= value <= 127 for value in text + pattern):
            return -1, b""
        positions = []
        if pattern_length <= text_length:
            positions = [start for start in range(text_length - pattern_length + 1)
                         if text[start:start + pattern_length] == pattern]
        output = bytes(positions)
        return len(output), output

    if algorithm == "boyer_moore_horspool":
        if (not 2 <= len(values) <= 512
                or any(type(value) is not int for value in values)):
            return -1, b""
        text_length, pattern_length = values[:2]
        if (not 0 <= text_length <= 255 or not 0 <= pattern_length <= 255
                or len(values) != 2 + text_length + pattern_length):
            return -1, b""
        text = values[2:2 + text_length]
        pattern = values[2 + text_length:]
        if any(not 0 <= value <= 127 for value in text + pattern):
            return -1, b""
        positions = []
        if pattern_length == 0:
            positions = list(range(text_length + 1))
        elif pattern_length <= text_length:
            shifts = [pattern_length] * 128
            for index in range(pattern_length - 1):
                shifts[pattern[index]] = pattern_length - 1 - index
            start = 0
            while start <= text_length - pattern_length:
                current = pattern_length
                while current > 0 and pattern[current - 1] == text[start + current - 1]:
                    current -= 1
                if current == 0:
                    positions.append(start)
                    start += 1
                else:
                    start += shifts[text[start + pattern_length - 1]]
        output = bytes(positions)
        return len(output), output

    if algorithm == "naive_search":
        if (not 2 <= len(values) <= 512
                or any(type(value) is not int for value in values)):
            return -1, b""
        text_length, pattern_length = values[:2]
        if (not 0 <= text_length <= 255 or not 0 <= pattern_length <= 255
                or len(values) != 2 + text_length + pattern_length):
            return -1, b""
        text = values[2:2 + text_length]
        pattern = values[2 + text_length:]
        if any(not 1 <= value <= 127 for value in text + pattern):
            return -1, b""
        positions = []
        if pattern_length <= text_length:
            positions = [start for start in range(text_length - pattern_length + 1)
                         if text[start:start + pattern_length] == pattern]
        output = bytes(positions)
        return len(output), output

    if algorithm == "dna":
        if (not 1 <= len(values) <= 1001
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        if mode != 0 or any(value not in (65, 67, 71, 84) for value in payload):
            return -1, b""
        complement = {65: 84, 84: 65, 67: 71, 71: 67}
        output = bytes(complement[base] for base in payload)
        return len(output), output

    if algorithm == "dna2_rna":
        if (not 1 <= len(values) <= 1001
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        if mode != 0 or any(not 65 <= value <= 90 for value in payload):
            return -1, b""
        output = bytes(85 if base == 84 else base for base in payload)
        return len(output), output

    if algorithm == "rna_transcription":
        if (not 1 <= len(values) <= 1001
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        if mode != 0 or any(not 0 <= value <= 255 for value in payload):
            return -1, b""
        transcription = {ord("A"): ord("U"), ord("C"): ord("G"),
                         ord("G"): ord("C"), ord("T"): ord("A")}
        if any(base not in transcription for base in payload):
            return -1, b""
        output = bytes(transcription[base] for base in payload)
        return len(output), output

    if algorithm == "base85":
        if (not 1 <= len(values) <= 66
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        if mode == 0:
            if any(not 0 <= value <= 255 for value in payload):
                return -1, b""
            output = bytearray()
            for offset in range(0, len(payload), 4):
                chunk = payload[offset:offset + 4]
                value = int.from_bytes(bytes(chunk) + bytes(4 - len(chunk)), "big")
                digits = [0] * 5
                for index in range(4, -1, -1):
                    digits[index] = value % 85
                    value //= 85
                output.extend(33 + digit for digit in digits[:5 if len(chunk) == 4 else len(chunk) + 1])
            return len(output), bytes(output)
        if mode != 1 or any(not 0 <= value <= 255 for value in payload) or len(payload) % 5 == 1:
            return -1, b""
        output = bytearray()
        for offset in range(0, len(payload), 5):
            chunk = payload[offset:offset + 5]
            if any(not 33 <= value <= 117 for value in chunk):
                return -1, b""
            value = 0
            for index in range(5):
                digit = chunk[index] - 33 if index < len(chunk) else 84
                value = value * 85 + digit
            if value > 0xFFFFFFFF:
                return -1, b""
            output.extend(value.to_bytes(4, "big")[:4 if len(chunk) == 5 else len(chunk) - 1])
        if len(output) > 52:
            return -1, b""
        return len(output), bytes(output)

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

    if algorithm == "binary_to_excess3":
        if (not 1 <= len(values) <= 128
                or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
            return -1, b""
        try:
            number = int(bytes(values).decode("ascii"), 2)
        except ValueError:
            return -1, b""
        if abs(number) > 1 << 62:
            return -1, b""
        encoded = format(number + 3, "04b").encode("ascii")
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

    if algorithm == "findpalindrome":
        if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
                or any(type(value) is not int or not 32 <= value <= 126 for value in values)):
            return -1, b""
        punctuation = set(b'!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~')
        words = []
        for raw in bytes(values).split(b" "):
            word = bytes(value for value in raw if value not in punctuation)
            if len(word) > 1 and word.lower() == word[::-1].lower():
                words.append(word)
        output = b"\0".join(words)
        return len(output), output

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
        max_input_length = (MAX_BACONIAN_PAYLOAD_LENGTH + 2 if algorithm == "baconian_cipher" else
                            MAX_BURROWS_WHEELER_LENGTH + 1 if algorithm in {
                                "burrows_wheeler_transform", "burrows_wheeler_transform_case_insensitive"} else
                            MAX_MATRIX_INPUT_LENGTH if algorithm == "ones_minus_zeros" else
                            MAX_ACCOUNT_MERGE_INPUT_LENGTH if algorithm == "account_merge" else
                            MAX_A_STAR_INPUT_LENGTH if algorithm == "a_star_search" else
                            MAX_NAIVE_SHUFFLER_INPUT_LENGTH if algorithm == "naive_shuffler" else
                            MAX_AFFINE_CIPHER_INPUT_LENGTH if algorithm == "affine_cipher" else
                            MAX_SQUARE_STREAK_INPUT_LENGTH if algorithm == "longest_square_streak" else
                            MAX_SQUARED_ARRAY_INPUT_LENGTH if algorithm == "squares_of_a_sorted_array" else
                            MAX_SORT_ARRAY_BY_PARITY_INPUT_LENGTH if algorithm == "sort_array_by_parity" else
                            MAX_WAVE_SORT_INPUT_LENGTH if algorithm in {"wave_sort", "wave_sort_greedy", "wiggle_sort", "simplified_wiggle_sort", "wiggle_sort_strict"} else
                            MAX_FIND_DUPLICATES_INPUT_LENGTH + 1 if algorithm == "find_all_duplicates_in_array" else
                            MAX_REDUNDANT_CONNECTION_INPUT_LENGTH + 2 if algorithm == "redundant_connection" else
                            MAX_INPUT_LENGTH)
        if (not isinstance(values, list) or len(values) > max_input_length
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            raise ValueError(f"invalid signed 64-bit digit array in {case['id']}")
        if case.get("input_length") not in (None, len(values)):
            raise ValueError(f"declared input length differs for {case['id']}")
        required_count, required_output = expected_output(values, algorithm)
        float64_vector = workload.get("output", {}).get("kind") == "float64_vector"
        if float64_vector and algorithm not in {"quadratic_roots", "npv_sensitivity"}:
            raise ValueError(f"unsupported float64 vector algorithm {algorithm}")
        absolute_tolerance = workload["output"].get("absolute_tolerance", 0.0) if float64_vector else 0.0
        relative_tolerance = workload["output"].get("relative_tolerance", 0.0) if float64_vector else 0.0
        if (float64_vector and (not math.isfinite(absolute_tolerance) or absolute_tolerance < 0
                                or not math.isfinite(relative_tolerance) or relative_tolerance < 0)):
            raise ValueError("float64 vector tolerances must be finite and nonnegative")
        output_capacity = case.get("workspace_bytes", len(required_output))
        if (type(output_capacity) is not int or not 0 <= output_capacity <= MAX_OUTPUT_CAPACITY):
            raise ValueError(f"invalid output capacity in {case['id']}")
        if output_capacity < len(required_output):
            expected_count = case.get("capacity_error_result", -2)
            expected = b""
        else:
            expected_count, expected = required_count, required_output
        if case.get("expected_result") != expected_count:
            raise ValueError(f"workload oracle mismatch for {case['id']}")
        if float64_vector:
            declared_vector = case.get("expected_output")
            if (not isinstance(declared_vector, list)
                    or any(type(value) not in (int, float) or not math.isfinite(value)
                           for value in declared_vector)):
                raise ValueError(f"invalid float64 expected output vector for {case['id']}")
            if output_capacity < len(required_output) or expected_count < 0:
                oracle_vector = []
            else:
                oracle_vector = [struct.unpack_from("<d", required_output, offset)[0]
                                 for offset in range(0, len(required_output), 8)]
            if len(declared_vector) != len(oracle_vector) or any(
                    abs(actual - reference) > absolute_tolerance + relative_tolerance * abs(reference)
                    for actual, reference in zip(declared_vector, oracle_vector)):
                raise ValueError(f"workload float64 vector disagrees with the oracle for {case['id']}")
            expected = b"".join(struct.pack("<d", float(value)) for value in declared_vector)
        if (not float64_vector and "expected_output_hex" in case
                and case["expected_output_hex"].lower() != expected.hex()):
            raise ValueError(f"workload output bytes disagree with the oracle for {case['id']}")
        if (not float64_vector and "expected_output" in case
                and case["expected_output"].encode("utf-8") != expected):
            raise ValueError(f"workload output text disagrees with the oracle for {case['id']}")
        output_hex = expected.hex() if expected else "-"
        command = [str(executable), "--stdin", str(samples), str(warmups), str(repetitions)]
        runner_input = (f"{len(values)} {expected_count} {len(expected)} {output_capacity} "
                        + " ".join(map(str, values)) + " " + output_hex)
        if float64_vector:
            runner_input += f" float64_vector {absolute_tolerance:.17g} {relative_tolerance:.17g}"
        runner_input += "\n"
        completed = subprocess.run(command, input=runner_input, capture_output=True,
                                   text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"byte-output runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        expected_checksum = (fnv1a(expected) * repetitions * samples) & ((1 << 64) - 1)
        if (raw["observed_result"] != expected_count or len(raw["samples_ns"]) != samples
                or (not float64_vector and raw["result_checksum"] != expected_checksum)):
            raise ValueError(f"byte-output runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(values), "input_values": values,
                                     "case": case["id"], "target": None,
                                     "output_capacity": output_capacity,
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
