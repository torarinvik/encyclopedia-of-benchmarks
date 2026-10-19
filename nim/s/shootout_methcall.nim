const MinCalls = -100_000'i64
const MaxCalls = 100_000'i64
const MaxOutputBytes = 14

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

proc appendState(staged: var array[MaxOutputBytes, uint8], used: var int, state: bool) =
  let word = if state: "true" else: "false"
  for character in word:
    staged[used] = uint8(ord(character))
    inc used
  staged[used] = 10'u8
  inc used
  staged[used] = 10'u8
  inc used

proc shootout_methcall*(calls: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "shootout_methcall".} =
  if calls < MinCalls or calls > MaxCalls: return -1
  if output.isNil: return -2
  var toggle = Toggle(state: true, activate: toggleActivate, value: toggleValue)
  var nthToggle = NthToggle(
    state: true, countMax: 3, counter: 0,
    activate: nthToggleActivate, value: nthToggleValue
  )
  var toggleResult = true
  var nthResult = true
  let iterations = if calls > 0: int(calls) else: 0
  for _ in 0 ..< iterations:
    toggle.activate(toggle)
    toggleResult = toggle.value(addr toggle)
  for _ in 0 ..< iterations:
    nthToggle.activate(nthToggle)
    nthResult = nthToggle.value(addr nthToggle)
  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  appendState(staged, used, toggleResult)
  appendState(staged, used, nthResult)
  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
