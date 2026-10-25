"""Independent bounded oracle for the Olden health-system simulation."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
import struct

MAX_LEVEL = 4
MAX_TICKS = 40
SOURCE_SEED = 1
IA = 16807
IM = 2147483647
IQ = 127773
IR = 2836
MASK = 123459876


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


@dataclass
class _Patient:
    hospital_visits: int = 0
    elapsed: int = 0
    time_left: int = 0


@dataclass
class _Village:
    label: int
    level: int
    seed: int
    free_personnel: int
    waiting: deque[int] = field(default_factory=deque)
    assessing: deque[int] = field(default_factory=deque)
    inside: deque[int] = field(default_factory=deque)
    referring_up: deque[int] = field(default_factory=deque)


def _next_random(village: _Village) -> float:
    state = village.seed ^ MASK
    quotient = state // IQ
    state = IA * (state - quotient * IQ) - IR * quotient
    state ^= MASK
    if state < 0:
        state += IM
    value = _f32((1.0 / IM) * state)
    village.seed = int(_f32(value * _f32(IM)))
    return value


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the number of patients discharged by the bounded simulator."""
    if len(values) != 3 or any(type(value) is not int for value in values):
        return -1
    level, ticks, seed = values
    if not (1 <= level <= MAX_LEVEL and 0 <= ticks <= MAX_TICKS and seed == SOURCE_SEED):
        return -1

    village_count = sum(4**depth for depth in range(level))
    villages = [_Village(0, level, 0, 1 << (level - 1))]
    for label in range(1, village_count):
        parent = (label - 1) // 4
        node_level = villages[parent].level - 1
        villages.append(
            _Village(label, node_level, label * (IQ + seed), 1 << (node_level - 1))
        )

    postorder: list[int] = []

    def visit(label: int) -> None:
        for offset in range(4, 0, -1):
            child = label * 4 + offset
            if child < village_count:
                visit(child)
        postorder.append(label)

    visit(0)
    patients: list[_Patient] = []
    discharged = 0

    def admit(village: _Village, patient_id: int) -> None:
        patient = patients[patient_id]
        patient.hospital_visits += 1
        if village.free_personnel > 0:
            village.free_personnel -= 1
            patient.time_left = 3
            patient.elapsed += 3
            village.assessing.append(patient_id)
        else:
            village.waiting.append(patient_id)

    for _ in range(ticks):
        for label in postorder:
            village = villages[label]

            for offset in range(4, 0, -1):
                child_label = label * 4 + offset
                if child_label >= village_count:
                    continue
                child = villages[child_label]
                while child.referring_up:
                    admit(village, child.referring_up.popleft())

            for _ in range(len(village.inside)):
                patient_id = village.inside.popleft()
                patient = patients[patient_id]
                patient.time_left -= 1
                if patient.time_left == 0:
                    village.free_personnel += 1
                    discharged += 1
                else:
                    village.inside.append(patient_id)

            for _ in range(len(village.assessing)):
                patient_id = village.assessing.popleft()
                patient = patients[patient_id]
                patient.time_left -= 1
                if patient.time_left == 0:
                    random_value = _next_random(village)
                    if random_value > 0.1 or village.label == 0:
                        patient.time_left = 10
                        patient.elapsed += 10
                        village.inside.append(patient_id)
                    else:
                        village.free_personnel += 1
                        village.referring_up.append(patient_id)
                else:
                    village.assessing.append(patient_id)

            for _ in range(len(village.waiting)):
                patient_id = village.waiting.popleft()
                patient = patients[patient_id]
                if village.free_personnel > 0:
                    village.free_personnel -= 1
                    patient.time_left = 3
                    patient.elapsed += 3
                    village.assessing.append(patient_id)
                else:
                    patient.elapsed += 1
                    village.waiting.append(patient_id)

            if _next_random(village) > 0.666:
                patient_id = len(patients)
                patients.append(_Patient())
                admit(village, patient_id)

    return discharged
