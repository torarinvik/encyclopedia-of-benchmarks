# Independent bounded Richards packet scheduler; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn richards_append(packet: Int, head: Int, mut links: InlineArray[Int, 9]) -> Int:
    links[packet] = 0
    if head == 0: return packet
    var tail = head
    while links[tail] != 0: tail = links[tail]
    links[tail] = packet
    return head

fn richards_enqueue(packet: Int, sender: Int,
                    mut links: InlineArray[Int, 9], mut ids: InlineArray[Int, 9],
                    mut queues: InlineArray[Int, 7], mut states: InlineArray[Int, 7],
                    mut packet_count: Int64) -> Int:
    let destination = ids[packet]
    packet_count += 1
    links[packet] = 0
    ids[packet] = sender
    if queues[destination] == 0:
        queues[destination] = packet
        states[destination] = states[destination] | 1
        # Priorities are 0, 1000, ..., 5000 in task-ID order.
        if destination > sender: return destination
    else:
        queues[destination] = richards_append(packet, queues[destination], links)
    return sender

@export("richards_benchmark")
fn richards_benchmark(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let iterations = input[0]
    if iterations < 1 or iterations > 1_000_000: return -1

    # Index zero is the null packet or task. Eight packets are reused.
    var links = InlineArray[Int, 9](fill=0)
    var ids = InlineArray[Int, 9](fill=0)
    var kinds = InlineArray[Int, 9](fill=1000)
    var a1 = InlineArray[Int, 9](fill=0)
    var a2 = InlineArray[Int, 36](fill=0)
    links[2] = 1
    kinds[1] = 1001; kinds[2] = 1001
    links[4] = 3; links[5] = 4
    links[7] = 6; links[8] = 7
    for p in range(3, 6): ids[p] = 5
    for p in range(6, 9): ids[p] = 6

    var queues = InlineArray[Int, 7](fill=0)
    queues[2] = 2; queues[3] = 5; queues[4] = 8
    var states = InlineArray[Int, 7](fill=2)
    states[1] = 0; states[2] = 3; states[3] = 3; states[4] = 3
    var v1 = InlineArray[Int, 7](fill=0)
    var v2 = InlineArray[Int, 7](fill=0)
    v1[1] = 1; v2[1] = Int(iterations); v1[2] = 3
    var packet_count = Int64(0)
    var hold_count = Int64(0)
    var current = 6
    while current != 0:
        let task = current
        var packet = 0
        if states[task] == 3:
            packet = queues[task]
            queues[task] = links[packet]
            states[task] = 0 if queues[task] == 0 else 1
        let state = states[task]
        if state != 0 and state != 1:
            if state == 2 or state == 4 or state == 5 or state == 6 or state == 7:
                current = task - 1
                continue
            return -1

        if task == 1:
            v2[task] -= 1
            if v2[task] == 0:
                hold_count += 1; states[task] = states[task] | 4
                current = 0
            else:
                var destination = 5
                if (v1[task] & 1) == 0:
                    v1[task] = (v1[task] >> 1) & 32767
                else:
                    v1[task] = ((v1[task] >> 1) & 32767) ^ 0xD008
                    destination = 6
                states[destination] = states[destination] & ~4
                current = destination if destination > task else task
        elif task == 2:
            if packet == 0:
                states[task] = states[task] | 2; current = task
            else:
                v1[task] = 7 - v1[task]
                ids[packet] = v1[task]; a1[packet] = 0
                for i in range(4):
                    v2[task] += 1
                    if v2[task] > 26: v2[task] = 1
                    a2[4*packet+i] = 64 + v2[task]
                current = richards_enqueue(packet, task, links, ids, queues, states, packet_count)
        elif task == 3 or task == 4:
            if packet != 0:
                if kinds[packet] == 1001:
                    v1[task] = richards_append(packet, v1[task], links)
                else:
                    v2[task] = richards_append(packet, v2[task], links)
            let work = v1[task]
            if work != 0 and a1[work] > 3:
                v1[task] = links[work]
                current = richards_enqueue(work, task, links, ids, queues, states, packet_count)
            elif work != 0 and v2[task] != 0:
                let device = v2[task]
                v2[task] = links[device]
                a1[device] = a2[4*work+a1[work]]
                a1[work] += 1
                current = richards_enqueue(device, task, links, ids, queues, states, packet_count)
            else:
                states[task] = states[task] | 2; current = task
        else:
            if packet != 0:
                v1[task] = packet
                hold_count += 1; states[task] = states[task] | 4
                current = task - 1
            elif v1[task] != 0:
                packet = v1[task]; v1[task] = 0
                current = richards_enqueue(packet, task, links, ids, queues, states, packet_count)
            else:
                states[task] = states[task] | 2; current = task
    return packet_count * Int64(2147483648) + hold_count
