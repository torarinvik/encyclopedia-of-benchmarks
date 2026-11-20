from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_S = Int64(4222124650659840)
comptime RESULT_FACTOR = MAX_S + Int64(1)

@export("tunstall_codebook_construction")
fn tunstall_codebook_construction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 7: return -1
    if input[0] < 2 or input[0] > 4 or input[1] < 2 or input[1] > 4: return -1
    let k = Int(input[0])
    let bits = Int(input[1])
    if length != c_size_t(k + 2): return -1
    var weights = InlineArray[Int64, 4](fill=0)
    var total: Int64 = 0
    for i in range(k):
        let weight = input[2 + i]
        if weight <= 0 or weight > 8: return -1
        weights[i] = weight
        total += weight
    if total > 8: return -1

    var powers = InlineArray[Int64, 17](fill=0)
    powers[0] = 1
    for i in range(1, 17): powers[i] = powers[i - 1] * total
    var cap = 1
    for bit in range(bits): cap *= 2
    var target = cap
    while (target - 1) % (k - 1) != 0: target -= 1

    var products = InlineArray[Int64, 31](fill=0)
    var depths = InlineArray[Int, 31](fill=0)
    var phraseKeys = InlineArray[UInt64, 31](fill=0)
    var leaves = InlineArray[Int, 16](fill=0)
    var nodeCount = 1
    var leafCount = 0
    for symbol in range(k):
        let node = nodeCount
        nodeCount += 1
        products[node] = weights[symbol]
        depths[node] = 1
        phraseKeys[node] = UInt64(symbol + 1) << 56
        leaves[leafCount] = node
        leafCount += 1

    var scaledExpectation = powers[16]
    while leafCount < target:
        var bestPosition = 0
        var bestNode = leaves[0]
        var bestProbability = products[bestNode] * powers[15 - depths[bestNode]]
        for position in range(1, leafCount):
            let candidate = leaves[position]
            let probability = products[candidate] * powers[15 - depths[candidate]]
            if probability > bestProbability or (probability == bestProbability and phraseKeys[candidate] < phraseKeys[bestNode]):
                bestPosition = position
                bestNode = candidate
                bestProbability = probability

        scaledExpectation += products[bestNode] * powers[16 - depths[bestNode]]
        leafCount -= 1
        leaves[bestPosition] = leaves[leafCount]
        for symbol in range(k):
            let child = nodeCount
            nodeCount += 1
            products[child] = products[bestNode] * weights[symbol]
            depths[child] = depths[bestNode] + 1
            let shift = 4 * (14 - depths[bestNode])
            phraseKeys[child] = phraseKeys[bestNode] | (UInt64(symbol + 1) << shift)
            leaves[leafCount] = child
            leafCount += 1
    if scaledExpectation > MAX_S: return -1
    Int64(target) * RESULT_FACTOR + scaledExpectation
