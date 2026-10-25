const
  MaxIterations = 1_000_000'i64
  Idle = 1
  Work = 2
  HandlerA = 3
  HandlerB = 4
  DeviceA = 5
  DeviceB = 6
  KDev = 1000
  KWork = 1001
  PktBit = 1
  WaitBit = 2
  HoldBit = 4
  RunState = 0
  RunPkt = 1
  WaitState = 2
  WaitPkt = 3
  HoldState = 4
  HoldPkt = 5
  HoldWait = 6
  HoldWaitPkt = 7
type
  Packet = object
    link, id, kind, a1: int
    a2: array[4, int]
  Task = object
    link, id, priority, queue, state: int
    v1, v2: int64
  Scheduler = object
    packets: array[9, Packet]
    tasks: array[7, Task]
    packetUsed, taskList, current, taskId, packetCount, holdCount: int
    v1, v2: int64

proc makePacket(s: var Scheduler, link, id, kind: int): int =
  inc s.packetUsed
  result = s.packetUsed
  s.packets[result] = Packet(link: link, id: id, kind: kind)

proc makeTask(s: var Scheduler, id, priority, queue, state: int, a, b: int64) =
  s.tasks[id] = Task(link: s.taskList, id: id, priority: priority, queue: queue,
                     state: state, v1: a, v2: b)
  s.taskList = id

proc appendPacket(s: var Scheduler, packet, head: int): int =
  s.packets[packet].link = 0
  if head == 0: return packet
  var tail = head
  while s.packets[tail].link != 0: tail = s.packets[tail].link
  s.packets[tail].link = packet
  head

proc queuePacket(s: var Scheduler, packet: int): int =
  let destination = s.packets[packet].id
  inc s.packetCount
  s.packets[packet].link = 0
  s.packets[packet].id = s.taskId
  if s.tasks[destination].queue == 0:
    s.tasks[destination].queue = packet
    s.tasks[destination].state = s.tasks[destination].state or PktBit
    if s.tasks[destination].priority > s.tasks[s.taskId].priority: return destination
  else:
    s.tasks[destination].queue = appendPacket(s, packet, s.tasks[destination].queue)
  s.current

proc releaseTask(s: var Scheduler, destination: int): int =
  s.tasks[destination].state = s.tasks[destination].state and not HoldBit
  if s.tasks[destination].priority > s.tasks[s.taskId].priority: return destination
  s.current

proc waitTask(s: var Scheduler): int =
  s.tasks[s.taskId].state = s.tasks[s.taskId].state or WaitBit
  s.taskId

proc holdTask(s: var Scheduler): int =
  inc s.holdCount
  s.tasks[s.taskId].state = s.tasks[s.taskId].state or HoldBit
  s.tasks[s.taskId].link

proc runTask(s: var Scheduler, packet: int): int =
  if s.taskId == Idle:
    dec s.v2
    if s.v2 == 0: return holdTask(s)
    if (s.v1 and 1) == 0:
      s.v1 = (s.v1 shr 1) and 32767
      return releaseTask(s, DeviceA)
    s.v1 = ((s.v1 shr 1) and 32767) xor 0xD008'i64
    return releaseTask(s, DeviceB)
  if s.taskId == Work:
    if packet == 0: return waitTask(s)
    s.v1 = int64(HandlerA + HandlerB) - s.v1
    s.packets[packet].id = int(s.v1)
    s.packets[packet].a1 = 0
    for index in 0..3:
      inc s.v2
      if s.v2 > 26: s.v2 = 1
      s.packets[packet].a2[index] = ord('A') + int(s.v2) - 1
    return queuePacket(s, packet)
  if s.taskId == HandlerA or s.taskId == HandlerB:
    if packet != 0:
      if s.packets[packet].kind == KWork:
        s.v1 = int64(appendPacket(s, packet, int(s.v1)))
      else:
        s.v2 = int64(appendPacket(s, packet, int(s.v2)))
    if s.v1 != 0:
      let workPacket = int(s.v1)
      let count = s.packets[workPacket].a1
      if count > 3:
        s.v1 = int64(s.packets[workPacket].link)
        return queuePacket(s, workPacket)
      if s.v2 != 0:
        let devicePacket = int(s.v2)
        s.v2 = int64(s.packets[devicePacket].link)
        s.packets[devicePacket].a1 = s.packets[workPacket].a2[count]
        s.packets[workPacket].a1 = count + 1
        return queuePacket(s, devicePacket)
    return waitTask(s)
  if packet == 0:
    if s.v1 == 0: return waitTask(s)
    result = int(s.v1)
    s.v1 = 0
    return queuePacket(s, result)
  s.v1 = int64(packet)
  holdTask(s)

proc schedule(s: var Scheduler): bool =
  while s.current != 0:
    var packet = 0
    let taskId = s.current
    if s.tasks[taskId].state == WaitPkt:
      packet = s.tasks[taskId].queue
      s.tasks[taskId].queue = s.packets[packet].link
      s.tasks[taskId].state = if s.tasks[taskId].queue == 0: RunState else: RunPkt
    let state = s.tasks[taskId].state
    if state == RunState or state == RunPkt:
      s.taskId = taskId
      s.v1 = s.tasks[taskId].v1
      s.v2 = s.tasks[taskId].v2
      s.current = runTask(s, packet)
      s.tasks[taskId].v1 = s.v1
      s.tasks[taskId].v2 = s.v2
    elif state == WaitState or state == HoldState or state == HoldPkt or state == HoldWait or state == HoldWaitPkt:
      s.current = s.tasks[taskId].link
    else:
      return false
  true

proc richards_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "richards_benchmark".} =
  if input == nil or length != 1: return -1
  if input[0] < 1 or input[0] > MaxIterations: return -1
  var s: Scheduler
  var work = makePacket(s, 0, 0, KWork)
  work = makePacket(s, work, 0, KWork)
  makeTask(s, Idle, 0, 0, RunState, 1, input[0])
  makeTask(s, Work, 1000, work, WaitPkt, HandlerA, 0)
  var handlerA = makePacket(s, 0, DeviceA, KDev)
  handlerA = makePacket(s, handlerA, DeviceA, KDev)
  handlerA = makePacket(s, handlerA, DeviceA, KDev)
  makeTask(s, HandlerA, 2000, handlerA, WaitPkt, 0, 0)
  var handlerB = makePacket(s, 0, DeviceB, KDev)
  handlerB = makePacket(s, handlerB, DeviceB, KDev)
  handlerB = makePacket(s, handlerB, DeviceB, KDev)
  makeTask(s, HandlerB, 3000, handlerB, WaitPkt, 0, 0)
  makeTask(s, DeviceA, 4000, 0, WaitState, 0, 0)
  makeTask(s, DeviceB, 5000, 0, WaitState, 0, 0)
  s.current = s.taskList
  if not schedule(s): return -1
  int64(s.packetCount) * 2_147_483_648'i64 + int64(s.holdCount)
