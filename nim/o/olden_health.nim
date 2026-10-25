const
  MaxLevel = 4
  MaxTicks = 40
  MaxVillages = 85
  MaxPatients = MaxVillages * MaxTicks
  Waiting = 0
  Assessing = 1
  Inside = 2
  Up = 3
  IA = 16807'i64
  IM = 2147483647'i64
  IQ = 127773'i64
  IR = 2836'i64
  Mask = 123459876'i64

type
  HealthPatient = object
    next: int
    previous: int
    timeLeft: int
    elapsed: int
    hospitalVisits: int
  HealthVillage = object
    label: int
    level: int
    freePersonnel: int
    seed: int64
    head: array[4, int]
    tail: array[4, int]

proc queuePush(village: var HealthVillage, queue, patientId: int,
               patients: var array[MaxPatients, HealthPatient]) =
  patients[patientId].previous = village.tail[queue]
  patients[patientId].next = -1
  if village.tail[queue] >= 0:
    patients[village.tail[queue]].next = patientId
  else:
    village.head[queue] = patientId
  village.tail[queue] = patientId

proc queueRemove(village: var HealthVillage, queue, patientId: int,
                 patients: var array[MaxPatients, HealthPatient]) =
  let previous = patients[patientId].previous
  let next = patients[patientId].next
  if previous >= 0:
    patients[previous].next = next
  else:
    village.head[queue] = next
  if next >= 0:
    patients[next].previous = previous
  else:
    village.tail[queue] = previous
  patients[patientId].next = -1
  patients[patientId].previous = -1

proc healthRandom(village: var HealthVillage): float32 =
  var state = village.seed xor Mask
  let quotient = state div IQ
  state = IA * (state - quotient * IQ) - IR * quotient
  state = state xor Mask
  if state < 0: state += IM
  let value = float32((1.0 / float64(IM)) * float64(state))
  village.seed = int64(value * float32(IM))
  value

proc admitPatient(village: var HealthVillage, patientId: int,
                  patients: var array[MaxPatients, HealthPatient]) =
  patients[patientId].hospitalVisits += 1
  if village.freePersonnel > 0:
    village.freePersonnel -= 1
    patients[patientId].timeLeft = 3
    patients[patientId].elapsed += 3
    queuePush(village, Assessing, patientId, patients)
  else:
    queuePush(village, Waiting, patientId, patients)

proc buildPostorder(label, villageCount: int,
                    order: var array[MaxVillages, int], orderLength: var int) =
  for offset in countdown(4, 1):
    let child = label * 4 + offset
    if child < villageCount: buildPostorder(child, villageCount, order, orderLength)
  order[orderLength] = label
  inc orderLength

proc simulateVillage(label, villageCount: int,
                     villages: var array[MaxVillages, HealthVillage],
                     patients: var array[MaxPatients, HealthPatient],
                     patientCount: var int, discharged: var int64) =
  for offset in countdown(4, 1):
    let childLabel = label * 4 + offset
    if childLabel >= villageCount: continue
    var patientId = villages[childLabel].head[Up]
    while patientId >= 0:
      let nextId = patients[patientId].next
      queueRemove(villages[childLabel], Up, patientId, patients)
      admitPatient(villages[label], patientId, patients)
      patientId = nextId

  var patientId = villages[label].head[Inside]
  while patientId >= 0:
    let nextId = patients[patientId].next
    dec patients[patientId].timeLeft
    if patients[patientId].timeLeft == 0:
      inc villages[label].freePersonnel
      queueRemove(villages[label], Inside, patientId, patients)
      inc discharged
    patientId = nextId

  patientId = villages[label].head[Assessing]
  while patientId >= 0:
    let nextId = patients[patientId].next
    dec patients[patientId].timeLeft
    if patients[patientId].timeLeft == 0:
      let randomValue = healthRandom(villages[label])
      queueRemove(villages[label], Assessing, patientId, patients)
      if float64(randomValue) > 0.1 or villages[label].label == 0:
        patients[patientId].timeLeft = 10
        patients[patientId].elapsed += 10
        queuePush(villages[label], Inside, patientId, patients)
      else:
        inc villages[label].freePersonnel
        queuePush(villages[label], Up, patientId, patients)
    patientId = nextId

  patientId = villages[label].head[Waiting]
  while patientId >= 0:
    let nextId = patients[patientId].next
    if villages[label].freePersonnel > 0:
      dec villages[label].freePersonnel
      patients[patientId].timeLeft = 3
      patients[patientId].elapsed += 3
      queueRemove(villages[label], Waiting, patientId, patients)
      queuePush(villages[label], Assessing, patientId, patients)
    else:
      inc patients[patientId].elapsed
    patientId = nextId

  if float64(healthRandom(villages[label])) > 0.666:
    let newPatient = patientCount
    inc patientCount
    patients[newPatient] = HealthPatient(next: -1, previous: -1, timeLeft: 0,
      elapsed: 0, hospitalVisits: 0)
    admitPatient(villages[label], newPatient, patients)

proc olden_health*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "olden_health".} =
  if input == nil or length != 3: return -1
  let level = input[0]
  let ticks = input[1]
  let seed = input[2]
  if level < 1 or level > MaxLevel or ticks < 0 or ticks > MaxTicks or seed != 1: return -1
  var villageCount = 0
  var layerSize = 1
  for _ in 0 ..< int(level):
    villageCount += layerSize
    layerSize *= 4

  var villages: array[MaxVillages, HealthVillage]
  for label in 0 ..< villageCount:
    villages[label].label = label
    villages[label].level = if label == 0: int(level) else: villages[(label - 1) div 4].level - 1
    villages[label].freePersonnel = 1 shl (villages[label].level - 1)
    villages[label].seed = int64(label) * (IQ + seed)
    for queue in 0 ..< 4:
      villages[label].head[queue] = -1
      villages[label].tail[queue] = -1

  var order: array[MaxVillages, int]
  var orderLength = 0
  buildPostorder(0, villageCount, order, orderLength)
  var patients: array[MaxPatients, HealthPatient]
  var patientCount = 0
  var discharged = 0'i64
  for _ in 0 ..< int(ticks):
    for index in 0 ..< orderLength:
      simulateVillage(order[index], villageCount, villages, patients, patientCount, discharged)
  discharged
