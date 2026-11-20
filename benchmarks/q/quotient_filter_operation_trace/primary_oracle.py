"""Bounded incremental standard-quotient-filter operation model.

Fingerprints are supplied directly. Operations locate runs from the SQF
metadata and shift only the affected circular interval; no quotient-origin map
is reconstructed.
"""

SLOTS = 8
Q_BITS = 3
R_BITS = 5
MAX_OPERATIONS = 32
MAX_ITEMS = 6
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_OPERATIONS
WORKSPACE_BYTES = 256


def _i64(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _next(index):
    return (index + 1) % SLOTS


def _prev(index):
    return (index - 1) % SLOTS


def _empty(index, remainders, occupied, continuation, shifted):
    return (remainders[index] == 0 and not occupied[index]
            and not continuation[index] and not shifted[index])


def _find_run_start(q, remainders, occupied, continuation, shifted):
    if not occupied[q]:
        return None
    bucket = q
    steps = 0
    while shifted[bucket] and steps < SLOTS:
        bucket = _prev(bucket)
        steps += 1
    if steps >= SLOTS:
        return None
    slot = bucket
    while bucket != q:
        # Advance to the next run head in the physical cluster.
        slot = _next(slot)
        steps = 0
        while continuation[slot] and steps < SLOTS:
            slot = _next(slot)
            steps += 1
        if steps >= SLOTS:
            return None
        bucket = _next(bucket)
        searched = 0
        while not occupied[bucket] and searched < SLOTS:
            bucket = _next(bucket)
            searched += 1
        if searched >= SLOTS:
            return None
    return slot


def _find_insert_position(q, occupied, continuation, shifted):
    """Return q's ordered run position by walking bucket/run metadata."""
    bucket = q
    steps = 0
    while shifted[bucket] and steps < SLOTS:
        bucket = _prev(bucket)
        steps += 1
    if steps >= SLOTS:
        return None

    slot = bucket
    while bucket != q:
        # Skip the run whose home is bucket, then advance the bucket cursor.
        steps = 0
        while steps < SLOTS:
            slot = _next(slot)
            steps += 1
            if not continuation[slot]:
                break
        else:
            return None

        bucket = _next(bucket)
        steps = 0
        while bucket != q and not occupied[bucket] and steps < SLOTS:
            bucket = _next(bucket)
            steps += 1
        if steps >= SLOTS:
            return None
    return slot


def _next_occupied_bucket(q, occupied):
    bucket = _next(q)
    for _ in range(SLOTS):
        if occupied[bucket]:
            return bucket
        bucket = _next(bucket)
    return None


def _insert_at(position, q, remainder, run_start, remainders, occupied,
               continuation, shifted):
    """Insert one sorted run member and shift only through the next hole."""
    in_existing_run = run_start is not None
    new_continuation = in_existing_run and position != run_start
    if in_existing_run and position == run_start:
        # The old head moves right and becomes a continuation.
        continuation[position] = True

    empty = position
    for _ in range(SLOTS):
        if _empty(empty, remainders, occupied, continuation, shifted):
            break
        empty = _next(empty)
    else:
        return False

    slot = empty
    while slot != position:
        previous = _prev(slot)
        remainders[slot] = remainders[previous]
        continuation[slot] = continuation[previous]
        shifted[slot] = True
        slot = previous

    remainders[position] = remainder
    continuation[position] = new_continuation
    shifted[position] = position != q
    occupied[q] = True
    return True


def _apply(records):
    remainders = [0] * SLOTS
    occupied = [False] * SLOTS
    continuation = [False] * SLOTS
    shifted = [False] * SLOTS
    total = 0
    statuses = bytearray()

    for opcode, fingerprint in records:
        q = fingerprint >> R_BITS
        remainder = fingerprint & ((1 << R_BITS) - 1)

        if opcode == 0:
            if total >= MAX_ITEMS:
                statuses.append(2)
                continue

            run_start = None
            if occupied[q]:
                position = _find_run_start(q, remainders, occupied,
                                           continuation, shifted)
                if position is None:
                    return -1, b""
                run_start = position
                for _ in range(SLOTS):
                    if remainders[position] > remainder:
                        break
                    nxt = _next(position)
                    if not continuation[nxt]:
                        position = nxt
                        break
                    position = nxt
            elif _empty(q, remainders, occupied, continuation, shifted):
                position = q
            else:
                position = _find_insert_position(q, occupied, continuation,
                                                 shifted)
                if position is None:
                    return -1, b""
            if not _insert_at(position, q, remainder, run_start, remainders,
                              occupied, continuation, shifted):
                return -1, b""
            total += 1
            statuses.append(1)

        elif opcode == 1:
            start = _find_run_start(q, remainders, occupied,
                                    continuation, shifted)
            found = False
            if start is not None:
                position = start
                for _ in range(SLOTS):
                    if remainders[position] == remainder:
                        found = True
                        break
                    if remainders[position] > remainder:
                        break
                    nxt = _next(position)
                    if not continuation[nxt]:
                        break
                    position = nxt
            statuses.append(1 if found else 0)

        else:
            start = _find_run_start(q, remainders, occupied,
                                    continuation, shifted)
            position = None
            if start is not None:
                cursor = start
                for _ in range(SLOTS):
                    if remainders[cursor] == remainder:
                        position = cursor
                        break
                    if remainders[cursor] > remainder:
                        break
                    nxt = _next(cursor)
                    if not continuation[nxt]:
                        break
                    cursor = nxt
            if position is None:
                statuses.append(0)
                continue

            was_run_start = not continuation[position]
            next_slot = _next(position)
            has_more_same_run = (not _empty(next_slot, remainders, occupied,
                                             continuation, shifted)
                                 and continuation[next_slot])
            if was_run_start and not has_more_same_run:
                occupied[q] = False
            remainders[position] = 0
            continuation[position] = False
            shifted[position] = False
            hole = position
            current_q = q
            first_shift = True
            for _ in range(SLOTS - 1):
                source = _next(hole)
                if (_empty(source, remainders, occupied, continuation, shifted)
                        or not shifted[source]):
                    break
                source_continuation = continuation[source]
                promoted_head = (first_shift and was_run_start
                                 and has_more_same_run)
                if not source_continuation and not promoted_head:
                    current_q = _next_occupied_bucket(current_q, occupied)
                    if current_q is None:
                        return -1, b""
                continuation[hole] = False if promoted_head else source_continuation
                remainders[hole] = remainders[source]
                shifted[hole] = (continuation[hole] or hole != current_q)
                remainders[source] = 0
                continuation[source] = False
                shifted[source] = False
                hole = source
                first_shift = False
            remainders[hole] = 0
            continuation[hole] = False
            shifted[hole] = False
            total -= 1
            statuses.append(1)

    return len(statuses), bytes(statuses)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    length = len(values)
    if not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _i64(word) for word in values):
        return -1, b""

    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or length != 1 + 2 * count:
        return -1, b""
    records = []
    for index in range(count):
        opcode, fingerprint = values[1 + 2 * index:3 + 2 * index]
        if opcode not in (0, 1, 2) or not 0 <= fingerprint <= 255:
            return -1, b""
        records.append((opcode, fingerprint))

    if output_is_null or (capacity is not None and capacity < count):
        return -2, b""
    return _apply(records)
