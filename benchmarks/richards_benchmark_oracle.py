"""Independent bounded oracle for the Richards packet-task scheduler."""

from __future__ import annotations

MAX_ITERATIONS = 1_000_000
MAX_INPUT_LENGTH = 2
INVALID_RESULT = -1
COUNTER_BASE = 1 << 31

I_IDLE, I_WORK, I_HANDLERA, I_HANDLERB, I_DEVA, I_DEVB = range(1, 7)
K_DEV, K_WORK = 1000, 1001
PKTBIT, WAITBIT, HOLDBIT = 1, 2, 4
S_RUN, S_RUNPKT, S_WAIT, S_WAITPKT = 0, 1, 2, 3
S_HOLD, S_HOLDPKT, S_HOLDWAIT, S_HOLDWAITPKT = 4, 5, 6, 7
BUFSIZE, MAXINT = 3, 32767
ALPHABET = "0ABCDEFGHIJKLMNOPQRSTUVWXYZ"
_RESULT_CACHE: dict[int, int] = {}


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 1 <= values[0] <= MAX_ITERATIONS):
        return INVALID_RESULT
    idle_count = values[0]
    if idle_count in _RESULT_CACHE:
        return _RESULT_CACHE[idle_count]

    # Packet zero is the null link. Packet records use indices rather than
    # Python object links, keeping this oracle independent of the C-like ports.
    packets: list[dict[str, object] | None] = [None]

    def new_packet(link: int, destination: int, kind: int) -> int:
        packets.append({"link": link, "id": destination, "kind": kind,
                        "a1": 0, "a2": [0, 0, 0, 0]})
        return len(packets) - 1

    work_head = new_packet(0, 0, K_WORK)
    work_head = new_packet(work_head, 0, K_WORK)
    handler_a_head = 0
    for _ in range(3):
        handler_a_head = new_packet(handler_a_head, I_DEVA, K_DEV)
    handler_b_head = 0
    for _ in range(3):
        handler_b_head = new_packet(handler_b_head, I_DEVB, K_DEV)

    tasks: list[dict[str, int]] = [{"next": 0, "id": 0, "priority": 0,
                                    "queue": 0, "state": 0, "v1": 0, "v2": 0}]
    definitions = {
        I_IDLE: (0, S_RUN, 1, idle_count),
        I_WORK: (1000, S_WAITPKT, I_HANDLERA, 0),
        I_HANDLERA: (2000, S_WAITPKT, 0, 0),
        I_HANDLERB: (3000, S_WAITPKT, 0, 0),
        I_DEVA: (4000, S_WAIT, 0, 0),
        I_DEVB: (5000, S_WAIT, 0, 0),
    }
    queues = {I_WORK: work_head, I_HANDLERA: handler_a_head,
              I_HANDLERB: handler_b_head}
    task_list = 0
    for task_id in range(I_IDLE, I_DEVB + 1):
        priority, state, v1, v2 = definitions[task_id]
        tasks.append({"next": task_list, "id": task_id, "priority": priority,
                      "queue": queues.get(task_id, 0), "state": state,
                      "v1": v1, "v2": v2})
        task_list = task_id
    current = task_list
    packet_count = hold_count = 0

    def append_packet(packet_index: int, head: int) -> int:
        packet = packets[packet_index]
        assert packet is not None
        packet["link"] = 0
        if head == 0:
            return packet_index
        tail = head
        while int(packets[tail]["link"]) != 0:  # type: ignore[index]
            tail = int(packets[tail]["link"])  # type: ignore[index]
        packets[tail]["link"] = packet_index  # type: ignore[index]
        return head

    def enqueue(packet_index: int, sender: int) -> int:
        nonlocal packet_count
        packet = packets[packet_index]
        assert packet is not None
        destination = int(packet["id"])
        target = tasks[destination]
        packet_count += 1
        packet["link"] = 0
        packet["id"] = sender
        if target["queue"] == 0:
            target["queue"] = packet_index
            target["state"] |= PKTBIT
            if target["priority"] > tasks[sender]["priority"]:
                return destination
        else:
            target["queue"] = append_packet(packet_index, target["queue"])
        return sender

    def release(destination: int, sender: int) -> int:
        target = tasks[destination]
        target["state"] &= ~HOLDBIT
        return destination if target["priority"] > tasks[sender]["priority"] else sender

    def hold(sender: int) -> int:
        nonlocal hold_count
        hold_count += 1
        tasks[sender]["state"] |= HOLDBIT
        return tasks[sender]["next"]

    def wait(sender: int) -> int:
        tasks[sender]["state"] |= WAITBIT
        return sender

    while current != 0:
        task = tasks[current]
        packet_index = 0
        state = task["state"]
        if state == S_WAITPKT:
            packet_index = task["queue"]
            packet = packets[packet_index]
            assert packet is not None
            task["queue"] = int(packet["link"])
            task["state"] = S_RUN if task["queue"] == 0 else S_RUNPKT
            state = task["state"]

        if state in (S_RUN, S_RUNPKT):
            task_id = current
            v1, v2 = task["v1"], task["v2"]
            if task_id == I_IDLE:
                v2 -= 1
                if v2 == 0:
                    next_task = hold(task_id)
                elif v1 & 1 == 0:
                    v1 = (v1 >> 1) & MAXINT
                    next_task = release(I_DEVA, task_id)
                else:
                    v1 = ((v1 >> 1) & MAXINT) ^ 0xD008
                    next_task = release(I_DEVB, task_id)
            elif task_id == I_WORK:
                if packet_index == 0:
                    next_task = wait(task_id)
                else:
                    packet = packets[packet_index]
                    assert packet is not None
                    v1 = I_HANDLERA + I_HANDLERB - v1
                    packet["id"] = v1
                    packet["a1"] = 0
                    for index in range(BUFSIZE + 1):
                        v2 += 1
                        if v2 > 26:
                            v2 = 1
                        packet["a2"][index] = ord(ALPHABET[v2])  # type: ignore[index]
                    next_task = enqueue(packet_index, task_id)
            elif task_id in (I_HANDLERA, I_HANDLERB):
                if packet_index != 0:
                    packet = packets[packet_index]
                    assert packet is not None
                    if packet["kind"] == K_WORK:
                        v1 = append_packet(packet_index, v1)
                    else:
                        v2 = append_packet(packet_index, v2)
                if v1 != 0:
                    work_packet = packets[v1]
                    assert work_packet is not None
                    count = int(work_packet["a1"])
                    if count > BUFSIZE:
                        completed_work_packet = v1
                        v1 = int(work_packet["link"])
                        next_task = enqueue(completed_work_packet, task_id)
                    elif v2 != 0:
                        device_index = v2
                        device_packet = packets[device_index]
                        assert device_packet is not None
                        v2 = int(device_packet["link"])
                        device_packet["a1"] = work_packet["a2"][count]  # type: ignore[index]
                        work_packet["a1"] = count + 1
                        next_task = enqueue(device_index, task_id)
                    else:
                        next_task = wait(task_id)
                else:
                    next_task = wait(task_id)
            else:
                if packet_index == 0:
                    if v1 == 0:
                        next_task = wait(task_id)
                    else:
                        packet_index = v1
                        v1 = 0
                        next_task = enqueue(packet_index, task_id)
                else:
                    v1 = packet_index
                    next_task = hold(task_id)
            task["v1"], task["v2"] = v1, v2
            current = next_task
        elif state in (S_WAIT, S_HOLD, S_HOLDPKT, S_HOLDWAIT, S_HOLDWAITPKT):
            current = task["next"]
        else:
            return INVALID_RESULT

    # Both counters use the source's signed-int representation. Packing by
    # 2**31 preserves each nonnegative 32-bit counter without overlap.
    result = packet_count * COUNTER_BASE + hold_count
    _RESULT_CACHE[idle_count] = result
    return result
