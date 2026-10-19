const MinN = -100_000'i64
const MaxN = 100_000'i64
const OutputBytes = 72

type
  Toggle = object
    state: bool
    activate: proc(toggle: var Toggle) {.nimcall.}
    value: proc(toggle: ptr Toggle): bool {.nimcall.}
  NthToggle = object
    state: bool
    countMax: int32
    counter: int32
    activate: proc(toggle: var NthToggle) {.nimcall.}
    value: proc(toggle: ptr NthToggle): bool {.nimcall.}

proc toggleActivate(toggle: var Toggle) =
  toggle.state = not toggle.state

proc toggleValue(toggle: ptr Toggle): bool = toggle.state

proc nthToggleActivate(toggle: var NthToggle) =
  inc toggle.counter
  if toggle.counter >= toggle.countMax:
    toggle.state = not toggle.state
    toggle.counter = 0

proc nthToggleValue(toggle: ptr NthToggle): bool = toggle.state

proc appendState(staged: var array[OutputBytes, uint8], used: var int, state: bool) =
  let word = if state: "true" else: "false"
  for character in word:
    staged[used] = uint8(ord(character))
    inc used
  staged[used] = 10'u8
  inc used

proc shootout_objinst*(n: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "shootout_objinst".} =
  if n < MinN or n > MaxN: return -1
  if output.isNil or outputCapacity < csize_t(OutputBytes): return -2

  var staged: array[OutputBytes, uint8]
  var used = 0
  let toggle = cast[ptr Toggle](allocShared0(sizeof(Toggle)))
  if toggle.isNil: return -1
  toggle[].state = true
  toggle[].activate = toggleActivate
  toggle[].value = toggleValue
  for _ in 0 ..< 5:
    let activate = toggle[].activate
    activate(toggle[])
    let value = toggle[].value
    appendState(staged, used, value(toggle))
  deallocShared(toggle)

  if n > 0:
    for _ in 0 ..< int(n):
      let extra = cast[ptr Toggle](allocShared0(sizeof(Toggle)))
      if extra.isNil: return -1
      extra[].state = true
      extra[].activate = toggleActivate
      extra[].value = toggleValue
      deallocShared(extra)

  staged[used] = 10'u8
  inc used
  let nthToggle = cast[ptr NthToggle](allocShared0(sizeof(NthToggle)))
  if nthToggle.isNil: return -1
  nthToggle[].state = true
  nthToggle[].countMax = 3
  nthToggle[].counter = 0
  nthToggle[].activate = nthToggleActivate
  nthToggle[].value = nthToggleValue
  for _ in 0 ..< 8:
    let activate = nthToggle[].activate
    activate(nthToggle[])
    let value = nthToggle[].value
    appendState(staged, used, value(nthToggle))
  deallocShared(nthToggle)

  if n > 0:
    for _ in 0 ..< int(n):
      let extra = cast[ptr NthToggle](allocShared0(sizeof(NthToggle)))
      if extra.isNil: return -1
      extra[].state = true
      extra[].countMax = 3
      extra[].counter = 0
      extra[].activate = nthToggleActivate
      extra[].value = nthToggleValue
      deallocShared(extra)

  if used != OutputBytes: return -1
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
