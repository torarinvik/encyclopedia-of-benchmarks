const
  MaxAccounts = 64
  MaxEmailReferences = 1024
  EmailTableSize = 2048

type EmailRef = object
  start, length, account, root: int

proc compareText(values: ptr UncheckedArray[int64], leftStart, leftLength,
    rightStart, rightLength: int): int =
  let shared = min(leftLength, rightLength)
  for i in 0 ..< shared:
    if values[leftStart + i] < values[rightStart + i]: return -1
    if values[leftStart + i] > values[rightStart + i]: return 1
  if leftLength < rightLength: -1
  elif leftLength > rightLength: 1
  else: 0

proc emailHash(values: ptr UncheckedArray[int64], start, length: int): uint64 =
  result = 14695981039346656037'u64
  for i in 0 ..< length:
    result = (result xor uint64(uint8(values[start + i]))) *% 1099511628211'u64

proc findRoot(parent: var array[MaxAccounts, int], value: int): int =
  result = value
  while parent[result] != result:
    parent[result] = parent[parent[result]]
    result = parent[result]

proc joinAccounts(parent: var array[MaxAccounts, int], rank: var array[MaxAccounts, int], left, right: int) =
  let leftRoot = findRoot(parent, left)
  let rightRoot = findRoot(parent, right)
  if leftRoot == rightRoot: return
  if rank[leftRoot] < rank[rightRoot]: parent[leftRoot] = rightRoot
  elif rank[leftRoot] > rank[rightRoot]: parent[rightRoot] = leftRoot
  else:
    parent[rightRoot] = leftRoot
    inc rank[leftRoot]

proc sortEmails(values: ptr UncheckedArray[int64], emails: array[MaxEmailReferences, EmailRef],
    indices: var array[MaxEmailReferences, int], scratch: var array[MaxEmailReferences, int], count: int) =
  var width = 1
  while width < count:
    var low = 0
    while low < count:
      let middle = min(low + width, count)
      let high = min(middle + width, count)
      var left = low
      var right = middle
      var output = low
      while left < middle and right < high:
        let a = emails[indices[left]]
        let b = emails[indices[right]]
        if compareText(values, a.start, a.length, b.start, b.length) <= 0:
          scratch[output] = indices[left]
          inc left
        else:
          scratch[output] = indices[right]
          inc right
        inc output
      while left < middle:
        scratch[output] = indices[left]; inc left; inc output
      while right < high:
        scratch[output] = indices[right]; inc right; inc output
      for i in low ..< high: indices[i] = scratch[i]
      low = high
    if width > count div 2: break
    width *= 2

proc compareGroups(values: ptr UncheckedArray[int64], nameStart, nameLength,
    emailCount, firstEmail: array[MaxAccounts, int], emails: array[MaxEmailReferences, EmailRef],
    left, right: int): int =
  result = compareText(values, nameStart[left], nameLength[left], nameStart[right], nameLength[right])
  if result != 0: return
  if emailCount[left] == 0 or emailCount[right] == 0:
    if emailCount[left] != emailCount[right]:
      return (if emailCount[left] == 0: -1 else: 1)
    return cmp(left, right)
  let a = emails[firstEmail[left]]
  let b = emails[firstEmail[right]]
  result = compareText(values, a.start, a.length, b.start, b.length)
  if result == 0: result = cmp(left, right)

proc writeU16(output: ptr UncheckedArray[uint8], position: var int, value: int) =
  output[position] = uint8(value and 255); inc position
  output[position] = uint8((value shr 8) and 255); inc position

## Merge accounts sharing an email and encode the sorted groups as little-endian bytes.
proc account_merge*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "account_merge".} =
  if values == nil or length == 0: return -1
  if values[0] < 0 or values[0] > MaxAccounts: return -1
  if length > 100002: return -1
  let inputLength = int(length)
  let accountCount = int(values[0])
  var nameStart, nameLength: array[MaxAccounts, int]
  var parent, rank: array[MaxAccounts, int]
  var emails: array[MaxEmailReferences, EmailRef]
  var emailReferenceCount = 0
  var table: array[EmailTableSize, int]
  for i in 0 ..< EmailTableSize: table[i] = -1
  for i in 0 ..< accountCount: parent[i] = i
  var position = 1
  for account in 0 ..< accountCount:
    if position >= inputLength or values[position] < 1 or values[position] > 64: return -1
    let ownerLength = int(values[position]); inc position
    if ownerLength > inputLength - position: return -1
    nameStart[account] = position; nameLength[account] = ownerLength
    for j in 0 ..< ownerLength:
      if values[position + j] < 32 or values[position + j] > 126: return -1
    position += ownerLength
    if position >= inputLength or values[position] < 0 or values[position] > MaxEmailReferences: return -1
    let accountEmailCount = int(values[position]); inc position
    if accountEmailCount > MaxEmailReferences - emailReferenceCount: return -1
    for _ in 0 ..< accountEmailCount:
      if position >= inputLength or values[position] < 1 or values[position] > 64: return -1
      let emailLength = int(values[position]); inc position
      if emailLength > inputLength - position: return -1
      for j in 0 ..< emailLength:
        if values[position + j] < 33 or values[position + j] > 126: return -1
      emails[emailReferenceCount] = EmailRef(start: position, length: emailLength, account: account)
      var slot = int(emailHash(values, position, emailLength) and uint64(EmailTableSize - 1))
      while table[slot] >= 0:
        let previous = emails[table[slot]]
        if compareText(values, position, emailLength, previous.start, previous.length) == 0:
          joinAccounts(parent, rank, account, previous.account)
          break
        slot = (slot + 1) and (EmailTableSize - 1)
      if table[slot] < 0: table[slot] = emailReferenceCount
      inc emailReferenceCount
      position += emailLength
  if position != inputLength: return -1

  var groupRoots: array[MaxAccounts, int]
  var groupCount = 0
  var rootSeen: array[MaxAccounts, bool]
  var groupEmailCount, firstEmail: array[MaxAccounts, int]
  for account in 0 ..< accountCount:
    let root = findRoot(parent, account)
    if compareText(values, nameStart[account], nameLength[account], nameStart[root], nameLength[root]) != 0: return -1
    if not rootSeen[root]:
      rootSeen[root] = true; groupRoots[groupCount] = root; inc groupCount
  var uniqueIndices, emailScratch: array[MaxEmailReferences, int]
  var uniqueCount = 0
  for slot in 0 ..< EmailTableSize:
    if table[slot] < 0: continue
    let index = table[slot]
    emails[index].root = findRoot(parent, emails[index].account)
    inc groupEmailCount[emails[index].root]
    uniqueIndices[uniqueCount] = index; inc uniqueCount
  sortEmails(values, emails, uniqueIndices, emailScratch, uniqueCount)
  var firstSeen: array[MaxAccounts, bool]
  for i in 0 ..< uniqueCount:
    let root = emails[uniqueIndices[i]].root
    if not firstSeen[root]: firstSeen[root] = true; firstEmail[root] = uniqueIndices[i]
  for i in 1 ..< groupCount:
    let value = groupRoots[i]
    var destination = i
    while destination > 0 and compareGroups(values, nameStart, nameLength, groupEmailCount, firstEmail, emails, value, groupRoots[destination - 1]) < 0:
      groupRoots[destination] = groupRoots[destination - 1]; dec destination
    groupRoots[destination] = value
  var required = 2
  for g in 0 ..< groupCount:
    let root = groupRoots[g]
    required += 4 + nameLength[root]
    for i in 0 ..< uniqueCount:
      let email = emails[uniqueIndices[i]]
      if email.root == root: required += 2 + email.length
  if output == nil or outputCapacity < csize_t(required): return -2
  var outPosition = 0
  writeU16(output, outPosition, groupCount)
  for g in 0 ..< groupCount:
    let root = groupRoots[g]
    writeU16(output, outPosition, nameLength[root]); writeU16(output, outPosition, groupEmailCount[root])
    for j in 0 ..< nameLength[root]:
      output[outPosition] = uint8(values[nameStart[root] + j]); inc outPosition
    for i in 0 ..< uniqueCount:
      let email = emails[uniqueIndices[i]]
      if email.root != root: continue
      writeU16(output, outPosition, email.length)
      for j in 0 ..< email.length:
        output[outPosition] = uint8(values[email.start + j]); inc outPosition
  int64(outPosition)
