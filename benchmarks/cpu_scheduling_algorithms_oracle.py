"""Independent reference for the bounded CPU scheduling algorithm suite."""

from __future__ import annotations

MAX_PROCESSES = 32
MAX_ARRIVAL = 256
MAX_BURST = 32
MAX_PRIORITY = 32
MAX_QUANTUM = 32
MAX_INPUT_LENGTH = 3 + 4 * MAX_PROCESSES
MAX_OUTPUT_BYTES = MAX_PROCESSES * 56


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return status and seven little-endian i64 statistics per process."""
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""

    mode, raw_count, quantum = values[:3]
    if not 0 <= mode <= 5 or not 0 <= raw_count <= MAX_PROCESSES or not 1 <= quantum <= MAX_QUANTUM:
        return -1, b""
    count = raw_count
    if len(values) != 3 + 4 * count:
        return -1, b""

    processes: list[tuple[int, int, int, int]] = []
    identifiers: set[int] = set()
    for index in range(count):
        process_id, arrival, burst, priority = values[3 + 4 * index:7 + 4 * index]
        if (not 0 <= process_id < MAX_PROCESSES or process_id in identifiers
                or not 0 <= arrival <= MAX_ARRIVAL or not 1 <= burst <= MAX_BURST
                or not -MAX_PRIORITY <= priority <= MAX_PRIORITY):
            return -1, b""
        identifiers.add(process_id)
        processes.append((process_id, arrival, burst, priority))

    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return -1, b""
        if output_capacity < count * 56:
            return -2, b""

    remaining = [process[2] for process in processes]
    first_run = [-1] * count
    completion = [-1] * count
    time = 0
    done = 0

    if mode == 0:  # FCFS; Python's stable arrival sort preserves input order on ties.
        for index in sorted(range(count), key=lambda i: processes[i][1]):
            time = max(time, processes[index][1])
            first_run[index] = time
            time += processes[index][2]
            completion[index] = time
    elif mode in (1, 3):  # Non-preemptive SJF or priority.
        while done < count:
            ready = [i for i in range(count)
                     if completion[i] < 0 and processes[i][1] <= time]
            if not ready:
                time += 1
                continue
            if mode == 1:
                selected = min(ready, key=lambda i: (processes[i][2], processes[i][1], i))
            else:
                selected = min(ready, key=lambda i: (processes[i][3], i))
            first_run[selected] = time
            time += processes[selected][2]
            completion[selected] = time
            done += 1
    elif mode in (2, 4):  # Preemptive SJF or priority, one CPU tick at a time.
        while done < count:
            ready = [i for i in range(count)
                     if processes[i][1] <= time and remaining[i] > 0]
            if not ready:
                time += 1
                continue
            if mode == 2:
                selected = min(ready, key=lambda i: (remaining[i], processes[i][1], i))
            else:
                selected = min(ready, key=lambda i: (processes[i][3], i))
            if first_run[selected] < 0:
                first_run[selected] = time
            remaining[selected] -= 1
            time += 1
            if remaining[selected] == 0:
                completion[selected] = time
                done += 1
    else:  # Round Robin, appending arrivals before the running process is requeued.
        arrivals = sorted(range(count), key=lambda i: processes[i][1])
        next_arrival = 0
        ready_queue: list[int] = []
        while done < count:
            while (next_arrival < count
                   and processes[arrivals[next_arrival]][1] <= time):
                ready_queue.append(arrivals[next_arrival])
                next_arrival += 1
            if not ready_queue:
                time += 1
                continue
            selected = ready_queue.pop(0)
            run_for = min(quantum, remaining[selected])
            for _ in range(run_for):
                if first_run[selected] < 0:
                    first_run[selected] = time
                remaining[selected] -= 1
                time += 1
                while (next_arrival < count
                       and processes[arrivals[next_arrival]][1] <= time):
                    ready_queue.append(arrivals[next_arrival])
                    next_arrival += 1
            if remaining[selected] > 0:
                ready_queue.append(selected)
            else:
                completion[selected] = time
                done += 1

    output = bytearray()
    for index, (process_id, arrival, burst, _priority) in enumerate(processes):
        turnaround = completion[index] - arrival
        waiting = turnaround - burst
        response = first_run[index] - arrival
        for value in (process_id, arrival, burst, completion[index], turnaround, waiting, response):
            output.extend(value.to_bytes(8, "little", signed=True))
    return len(output), bytes(output)
