"""Reference oracle for the bounded virtual-clock time simulation."""

from __future__ import annotations

MAX_ACTIONS = 4096
MAX_VALID_INPUT_VALUES = 1 + 2 * MAX_ACTIONS
MAX_INPUT_LENGTH = MAX_VALID_INPUT_VALUES + 1  # one extra word for rejection
MAX_EVENTS = 1024
MAX_CUMULATIVE_FIRES = 4092
MAX_CALLBACK_LOG_CAPACITY = MAX_ACTIONS
MAX_TIMESTAMP = (1 << 63) - 1
MAX_EVENT_ID = (1 << 32) - 1
INVALID_RESULT = -1
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211


def _fnv_word(hash_value: int, word: int) -> int:
    for shift in range(0, 64, 8):
        hash_value ^= (word >> shift) & 0xFF
        hash_value = (hash_value * FNV_PRIME) & MASK64
    return hash_value


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the virtual-clock trace checksum, or -1 for invalid input."""
    if (not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT

    action_count = values[0]
    if not 0 <= action_count <= MAX_ACTIONS or len(values) != 1 + 2 * action_count:
        return INVALID_RESULT

    # None denotes a never-used slot; an inactive Event retains its old ID until
    # the next successful schedule reuses that first inactive slot.
    slots: list[dict[str, int | bool] | None] = [None] * MAX_EVENTS
    active_count = 0
    next_event_id = 1
    now = 0
    total_processed = 0
    action_results: list[int] = []
    fired: list[tuple[int, int]] = []

    for action_index in range(action_count):
        opcode = values[1 + 2 * action_index]
        operand = values[2 + 2 * action_index]

        if opcode == 0:  # schedule(timestamp)
            timestamp = operand
            if not 0 <= timestamp <= MAX_TIMESTAMP or timestamp < now:
                return INVALID_RESULT
            if active_count >= MAX_EVENTS:
                action_results.append(0)
                continue

            slot_index = next(
                index for index, event in enumerate(slots)
                if event is None or not event["active"]
            )
            event_id = next_event_id
            next_event_id = (next_event_id + 1) & MAX_EVENT_ID
            if next_event_id == 0:
                next_event_id = 1
            slots[slot_index] = {
                "timestamp": timestamp,
                "event_id": event_id,
                "active": True,
            }
            active_count += 1
            action_results.append(event_id)

        elif opcode == 1:  # cancel(event_id)
            if not 1 <= operand <= MAX_EVENT_ID:
                return INVALID_RESULT
            cancelled = False
            for event in slots:
                if (event is not None and event["active"]
                        and event["event_id"] == operand):
                    event["active"] = False
                    active_count -= 1
                    cancelled = True
                    break
            action_results.append(1 if cancelled else 0)

        elif opcode == 2:  # tick(target)
            target = operand
            if not 0 <= target <= MAX_TIMESTAMP or target < now:
                return INVALID_RESULT

            processed_this_tick = 0
            for _ in range(MAX_EVENTS):
                next_slot: int | None = None
                next_time = target + 1
                for index, event in enumerate(slots):
                    if (event is not None and event["active"]
                            and event["timestamp"] <= target
                            and event["timestamp"] < next_time):
                        next_slot = index
                        next_time = event["timestamp"]

                if next_slot is None:
                    break

                event = slots[next_slot]
                assert event is not None
                now = event["timestamp"]
                event["active"] = False
                active_count -= 1
                fired.append((event["event_id"], event["timestamp"]))
                processed_this_tick += 1
                total_processed += 1

            now = target
            action_results.append(processed_this_tick)

        elif opcode == 3:  # time()
            if operand != 0:
                return INVALID_RESULT
            action_results.append(now)

        elif opcode == 4:  # isEmpty()
            if operand != 0:
                return INVALID_RESULT
            action_results.append(1 if active_count == 0 else 0)

        else:
            return INVALID_RESULT

    words = [action_count, *action_results, len(fired)]
    if len(fired) > MAX_CUMULATIVE_FIRES:
        return INVALID_RESULT
    for event_id, timestamp in fired:
        words.extend((event_id, timestamp))
    words.extend((now, active_count, total_processed))

    result = FNV_OFFSET_BASIS
    for word in words:
        result = _fnv_word(result, word)
    return result & MASK63
