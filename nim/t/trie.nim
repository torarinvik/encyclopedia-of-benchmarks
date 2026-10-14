# Fixed-capacity lowercase trie with set semantics and subtree word counts.
proc trie_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "trie_benchmark".} =
  if length > 1024: return -1
  var children: array[26624, int]
  var terminal: array[1024, bool]
  var subtreeWords: array[1024, int]
  var usedNodes = 1
  var position = 0
  var operation = 0
  var checksum: int64 = 0
  var activeHashSum: int64 = 0

  while position < int(length):
    if position + 1 >= int(length): return -1
    let opcode = values[position]
    let wordLengthValue = values[position + 1]
    if opcode < 0 or opcode > 5 or wordLengthValue < 0 or wordLengthValue > 128: return -1
    let wordLength = int(wordLengthValue)
    if opcode == 5 and wordLength != 0: return -1
    if wordLength > int(length) - position - 2: return -1

    var wordHash = int64(wordLength + 1)
    for i in 0 ..< wordLength:
      let character = values[position + 2 + i]
      if character < 97 or character > 122: return -1
      wordHash = (wordHash * 31 + character - 96) mod 1000000007

    var node = 1
    var observed: int64 = 0
    if opcode == 0:
      for i in 0 ..< wordLength:
        let letter = int(values[position + 2 + i] - 97)
        let edge = (node - 1) * 26 + letter
        var child = children[edge]
        if child == 0:
          if usedNodes == 1024: return -1
          inc usedNodes
          child = usedNodes
          children[edge] = child
        node = child
      if not terminal[node - 1]:
        terminal[node - 1] = true
        node = 1
        inc subtreeWords[node - 1]
        for i in 0 ..< wordLength:
          let letter = int(values[position + 2 + i] - 97)
          node = children[(node - 1) * 26 + letter]
          inc subtreeWords[node - 1]
        activeHashSum += wordHash
        observed = 1
    else:
      var traversed = 0
      while traversed < wordLength and node != 0:
        let letter = int(values[position + 2 + traversed] - 97)
        node = children[(node - 1) * 26 + letter]
        inc traversed
      if traversed != wordLength: node = 0
      if opcode == 1:
        if node != 0 and terminal[node - 1]:
          terminal[node - 1] = false
          node = 1
          dec subtreeWords[node - 1]
          for i in 0 ..< wordLength:
            let letter = int(values[position + 2 + i] - 97)
            node = children[(node - 1) * 26 + letter]
            dec subtreeWords[node - 1]
          activeHashSum -= wordHash
          observed = 1
      elif opcode == 2:
        observed = int64(node != 0 and terminal[node - 1])
      elif opcode == 3:
        observed = int64(node != 0 and subtreeWords[node - 1] != 0)
      elif opcode == 4:
        if node != 0: observed = int64(subtreeWords[node - 1])
      else:
        observed = int64(subtreeWords[0])

    checksum += int64(operation + 1) * (observed + 1000000)
    inc operation
    position += 2 + wordLength

  checksum + int64(operation + 1) * (activeHashSum + 1000000)
