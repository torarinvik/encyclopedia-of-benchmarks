# Copyright (C) 1996-2006 Julian R Seward. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. The origin of this software must not be misrepresented; you must not claim
#    that you wrote the original software. If you use this software in a
#    product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 3. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 4. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# Julian Seward, Cambridge, UK. jseward@bzip.org
# bzip2/libbzip2 version 1.0.4 of 20 December 2006

"""Oracle for the bounded bzip2 MTF and zero-run coding stage."""

from __future__ import annotations

from collections.abc import Sequence

MAX_BLOCK_LENGTH = 32
MAX_TOKEN_COUNT = MAX_BLOCK_LENGTH + 1
MAX_INPUT_LENGTH = 3 + MAX_BLOCK_LENGTH + MAX_TOKEN_COUNT
MAX_OUTPUT_BYTES = MAX_TOKEN_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _emit_zero_run(tokens: list[int], count: int) -> None:
    if count <= 0:
        return
    value = count - 1
    while True:
        tokens.append(1 if value & 1 else 0)
        if value < 2:
            break
        value = (value - 2) // 2


def _encode(last_column: Sequence[int]) -> bytes:
    alphabet = sorted(set(last_column))
    order = list(range(len(alphabet)))
    tokens: list[int] = []
    pending_zeros = 0
    for symbol in last_column:
        rank = order.index(alphabet.index(symbol))
        if rank == 0:
            pending_zeros += 1
            continue
        _emit_zero_run(tokens, pending_zeros)
        pending_zeros = 0
        tokens.append(rank + 1)
        order.insert(0, order.pop(rank))
    _emit_zero_run(tokens, pending_zeros)
    tokens.append(len(alphabet) + 1)
    return bytes(tokens)


def _decode(alphabet: Sequence[int], tokens: Sequence[int]) -> bytes | None:
    eob = len(alphabet) + 1
    if len(tokens) < 2 or tokens[-1] != eob or eob in tokens[:-1]:
        return None
    order = list(alphabet)
    output: list[int] = []
    index = 0
    while index < len(tokens) - 1:
        token = tokens[index]
        if token in (0, 1):
            run_count = 0
            multiplier = 1
            while index < len(tokens) - 1 and tokens[index] in (0, 1):
                token = tokens[index]
                run_count += (token + 1) * multiplier
                if run_count > MAX_BLOCK_LENGTH or multiplier > MAX_BLOCK_LENGTH:
                    return None
                multiplier *= 2
                index += 1
            if run_count == 0 or len(output) + run_count > MAX_BLOCK_LENGTH:
                return None
            output.extend([order[0]] * run_count)
            continue
        if not 2 <= token < eob:
            return None
        rank = token - 1
        if rank >= len(order) or len(output) >= MAX_BLOCK_LENGTH:
            return None
        symbol = order.pop(rank)
        output.append(symbol)
        order.insert(0, symbol)
        index += 1
    return bytes(output)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 3
            or actual_length > MAX_INPUT_LENGTH or len(values) != actual_length):
        return INVALID_RESULT, b""

    mode, alphabet_count, payload_count = values[:3]
    if mode == 0:
        if (alphabet_count != 0 or not 1 <= payload_count <= MAX_BLOCK_LENGTH
                or actual_length != 3 + payload_count):
            return INVALID_RESULT, b""
        last_column = values[3:]
        if any(not 0 <= value <= 255 for value in last_column):
            return INVALID_RESULT, b""
        encoded = _encode(last_column)
    elif mode == 1:
        if (not 1 <= alphabet_count <= MAX_BLOCK_LENGTH
                or not 2 <= payload_count <= MAX_TOKEN_COUNT
                or actual_length != 3 + alphabet_count + payload_count):
            return INVALID_RESULT, b""
        alphabet = values[3:3 + alphabet_count]
        tokens = values[3 + alphabet_count:]
        if (any(not 0 <= value <= 255 for value in alphabet)
                or any(not 0 <= token <= alphabet_count + 1 for token in tokens)
                or any(alphabet[i] >= alphabet[i + 1] for i in range(alphabet_count - 1))):
            return INVALID_RESULT, b""
        decoded = _decode(alphabet, tokens)
        if decoded is None or not decoded:
            return INVALID_RESULT, b""
        encoded = decoded
    else:
        return INVALID_RESULT, b""

    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < len(encoded))):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
