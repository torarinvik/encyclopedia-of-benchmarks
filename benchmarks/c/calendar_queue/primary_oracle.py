"""Bounded Brown calendar-queue oracle using exact rational bucket widths."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from dataclasses import dataclass
from math import gcd

MAX_OPERATIONS = 128
MAX_LIVE = 64
MAX_PRIORITY = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS + 1
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH - 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * (MAX_OPERATIONS // 2))
WORKSPACE_BYTES = 8192


@dataclass(frozen=True)
class Event:
    priority: int
    event_id: int


class Calendar:
    def __init__(self) -> None:
        self.bucket_count = 2
        self.width_num = 1
        self.width_den = 1
        self.last_priority = 0
        self.last_bucket = 0
        self.bucket_top_num = 3
        self.bucket_top_den = 2
        self.events: list[Event] = []
        self.buckets: list[list[Event]] = [[], []]
        self.next_id = 0

    def _virtual_bucket(self, priority: int) -> int:
        return priority * self.width_den // self.width_num

    def _bucket_index(self, priority: int) -> int:
        return self._virtual_bucket(priority) % self.bucket_count

    def _reset_cursor(self, priority: int) -> None:
        virtual = self._virtual_bucket(priority)
        self.last_bucket = virtual % self.bucket_count
        # This is the current bucket's upper boundary plus Brown's half-width guard.
        self.bucket_top_num = (2 * virtual + 3) * self.width_num
        self.bucket_top_den = 2 * self.width_den

    def _insert_bucket(self, event: Event) -> None:
        bucket = self.buckets[self._bucket_index(event.priority)]
        key = (event.priority, event.event_id)
        at = 0
        while at < len(bucket) and (bucket[at].priority, bucket[at].event_id) < key:
            at += 1
        bucket.insert(at, event)

    def _new_width(self) -> tuple[int, int]:
        size = len(self.events)
        if size < 2:
            return 1, 1
        sample_count = size if size <= 5 else min(25, 5 + size // 10)
        earliest = sorted(self.events, key=lambda event: (event.priority, event.event_id))[:sample_count]
        gaps = [earliest[i + 1].priority - earliest[i].priority
                for i in range(sample_count - 1)]
        initial_sum = sum(gaps)
        if initial_sum == 0:
            return 1, 1
        denominator = len(gaps)
        kept = [gap for gap in gaps if gap * denominator <= 2 * initial_sum]
        kept_sum = sum(kept)
        if kept_sum == 0 or not kept:
            return 1, 1
        numerator = 3 * kept_sum
        denominator = len(kept)
        common = gcd(numerator, denominator)
        return numerator // common, denominator // common

    def _resize(self, new_count: int) -> None:
        width_num, width_den = self._new_width()
        old_events = self.events[:]
        self.bucket_count = new_count
        self.width_num = width_num
        self.width_den = width_den
        self.buckets = [[] for _ in range(new_count)]
        self._reset_cursor(self.last_priority)
        for event in old_events:
            self._insert_bucket(event)

    def enqueue(self, priority: int) -> bool:
        if not 0 <= priority <= MAX_PRIORITY or priority < self.last_priority:
            return False
        if len(self.events) >= MAX_LIVE:
            return False
        event = Event(priority, self.next_id)
        self.next_id += 1
        self.events.append(event)
        self._insert_bucket(event)
        if len(self.events) > 2 * self.bucket_count:
            self._resize(2 * self.bucket_count)
        return True

    def _remove(self, event: Event) -> None:
        bucket = self.buckets[self._bucket_index(event.priority)]
        bucket.remove(event)
        self.events.remove(event)

    def dequeue(self) -> Event | None:
        if not self.events:
            return None
        index = self.last_bucket
        while True:
            bucket = self.buckets[index]
            if (bucket and bucket[0].priority * self.bucket_top_den
                    < self.bucket_top_num):
                event = bucket[0]
                self._remove(event)
                self.last_bucket = index
                self.last_priority = event.priority
                if len(self.events) < self.bucket_count // 2 - 2:
                    self._resize(max(2, self.bucket_count // 2))
                return event

            index += 1
            if index == self.bucket_count:
                index = 0
            self.bucket_top_num += 2 * self.width_num
            if index == self.last_bucket:
                # Brown's direct search after a full calendar without a due head.
                event = min(
                    (items[0] for items in self.buckets if items),
                    key=lambda item: (item.priority, item.event_id),
                )
                self.last_priority = event.priority
                self._reset_cursor(event.priority)
                index = self.last_bucket


def _parse(values: Sequence[int]):
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 1 + 2 * operation_count:
        return None
    return list(zip(values[1::2], values[2::2]))


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    operations = _parse(values)
    if operations is None:
        return -1, b""

    queue = Calendar()
    trace: list[int] = []
    for opcode, argument in operations:
        if opcode == 1:
            if not queue.enqueue(argument):
                return -1, b""
        elif opcode == 2:
            if argument != 0:
                return -1, b""
            event = queue.dequeue()
            if event is None:
                return -1, b""
            trace.extend((event.event_id, event.priority))
        else:
            return -1, b""

    payload = b"".join(
        struct.pack("<q", word) for word in (len(trace) // 2, *trace)
    )
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
