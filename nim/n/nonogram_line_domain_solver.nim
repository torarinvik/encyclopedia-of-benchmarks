type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Domains = array[64, uint64]
  Parsed = object
    height, width: int
    clues: array[128, int64]
    counts: array[16, int]

proc parse(input: I64Input, length: csize_t, parsed: var Parsed): bool =
  if input == nil or length < 2 or input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8:
    return false
  parsed.height = int(input[0])
  parsed.width = int(input[1])
  if length != csize_t(2 + 5 * parsed.height + 5 * parsed.width): return false
  var offset = 2
  for group in 0..1:
    let lines = if group == 0: parsed.height else: parsed.width
    let lineLength = if group == 0: parsed.width else: parsed.height
    for line in 0..<lines:
      let index = if group == 0: line else: parsed.height + line
      let rawCount = input[offset]
      inc offset
      if rawCount < 0 or rawCount > 4: return false
      parsed.counts[index] = int(rawCount)
      var needed = if rawCount == 0: 0'i64 else: rawCount - 1
      for run in 0..<4:
        let value = input[offset]
        inc offset
        if run < parsed.counts[index]:
          if value <= 0 or value > int64(lineLength): return false
          parsed.clues[index * 8 + run] = value
          needed += value
        elif value != 0: return false
      if needed > int64(lineLength): return false
  var rowTotal = 0'i64
  var colTotal = 0'i64
  for row in 0..<parsed.height:
    for run in 0..<parsed.counts[row]: rowTotal += parsed.clues[row * 8 + run]
  for col in 0..<parsed.width:
    let line = parsed.height + col
    for run in 0..<parsed.counts[line]: colTotal += parsed.clues[line * 8 + run]
  rowTotal == colTotal

proc matches(mask: int, length: int, clues: array[128, int64], line: int, count: int): bool =
  var found = 0
  var run = 0
  for bit in 0..<length:
    if ((mask shr bit) and 1) != 0: inc run
    elif run != 0:
      if found >= count or clues[line * 8 + found] != int64(run): return false
      inc found
      run = 0
  if run != 0:
    if found >= count or clues[line * 8 + found] != int64(run): return false
    inc found
  found == count

proc has(domains: Domains, line: int, mask: int): bool =
  (domains[line * 4 + mask div 64] and (1'u64 shl (mask mod 64))) != 0

proc add(domains: var Domains, line: int, mask: int) =
  domains[line * 4 + mask div 64] = domains[line * 4 + mask div 64] or (1'u64 shl (mask mod 64))

proc domainCount(domains: Domains, line, length: int): int =
  for mask in 0..<(1 shl length):
    if has(domains, line, mask): inc result

proc filter(domains: var Domains, line, length, pos: int, allowZero, allowOne: bool): bool =
  for mask in 0..<(1 shl length):
    if not has(domains, line, mask): continue
    let one = ((mask shr pos) and 1) != 0
    if (if one: allowOne else: allowZero): continue
    domains[line * 4 + mask div 64] = domains[line * 4 + mask div 64] and not (1'u64 shl (mask mod 64))
    result = true

proc support(domains: Domains, line, length, pos: int, zero, one: var bool): bool =
  zero = false
  one = false
  for mask in 0..<(1 shl length):
    if not has(domains, line, mask): continue
    if ((mask shr pos) and 1) != 0: one = true else: zero = true
  zero or one

proc propagate(domains: var Domains, height, width: int): bool =
  var changed = true
  while changed:
    changed = false
    for row in 0..<height:
      for col in 0..<width:
        var rz, ro, cz, co: bool
        if not support(domains, row, width, col, rz, ro) or
            not support(domains, height + col, height, row, cz, co): return false
        if filter(domains, row, width, col, cz, co): changed = true
        if filter(domains, height + col, height, row, rz, ro): changed = true
        if domainCount(domains, row, width) == 0 or domainCount(domains, height + col, height) == 0: return false
  true

proc search(domains: var Domains, height, width: int): bool =
  if not propagate(domains, height, width): return false
  var branch = height
  for row in 0..<height:
    if domainCount(domains, row, width) > 1:
      branch = row
      break
  if branch == height: return true
  for mask in 0..<(1 shl width):
    if not has(domains, branch, mask): continue
    var trial = domains
    for word in 0..<4: trial[branch * 4 + word] = 0
    add(trial, branch, mask)
    if search(trial, height, width):
      domains = trial
      return true
  false

proc solve(parsed: Parsed, output: var array[64, uint8]): int =
  var domains: Domains
  for row in 0..<parsed.height:
    for mask in 0..<(1 shl parsed.width):
      if matches(mask, parsed.width, parsed.clues, row, parsed.counts[row]): add(domains, row, mask)
  for col in 0..<parsed.width:
    let line = parsed.height + col
    for mask in 0..<(1 shl parsed.height):
      if matches(mask, parsed.height, parsed.clues, line, parsed.counts[line]): add(domains, line, mask)
  for row in 0..<parsed.height:
    if domainCount(domains, row, parsed.width) == 0: return -1
  for col in 0..<parsed.width:
    if domainCount(domains, parsed.height + col, parsed.height) == 0: return -1
  if not search(domains, parsed.height, parsed.width): return -1
  for row in 0..<parsed.height:
    var mask = 0
    while mask < (1 shl parsed.width) and not has(domains, row, mask): inc mask
    for col in 0..<parsed.width:
      output[row * parsed.width + col] = uint8((mask shr col) and 1)
  parsed.height * parsed.width

proc nonogram_line_domain_solver*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "nonogram_line_domain_solver".} =
  var parsed: Parsed
  if not parse(input, length, parsed): return -1
  var bytes: array[64, uint8]
  let required = solve(parsed, bytes)
  if required < 0: return -1
  if output == nil or outputCapacity < csize_t(required): return -2
  for index in 0..<required: output[index] = bytes[index]
  int64(required)
