from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 20
comptime MAX_Q = 20
comptime MAX_PARSEABLE_INPUT = 123
comptime TREE_BASE = 32
comptime TREE_SIZE = 64
comptime MODULUS: Int64 = 1000000007
comptime HASH_BASE: Int64 = 911382323

fn rht_concat(left_hash: Int64, right_hash: Int64, right_length: Int,
        powers: InlineArray[Int64, MAX_N + 1]) -> Int64:
    return (left_hash * powers[right_length] + right_hash) % MODULUS

fn rht_pull(inout tree_hash: InlineArray[Int64, TREE_SIZE],
        inout tree_length: InlineArray[Int, TREE_SIZE], node: Int,
        powers: InlineArray[Int64, MAX_N + 1]):
    let left = 2 * node
    let right = left + 1
    tree_hash[node] = rht_concat(tree_hash[left], tree_hash[right],
        tree_length[right], powers)
    tree_length[node] = tree_length[left] + tree_length[right]

fn rht_hash_range(tree_hash: InlineArray[Int64, TREE_SIZE],
        tree_length: InlineArray[Int, TREE_SIZE], start_input: Int,
        end_input: Int, powers: InlineArray[Int64, MAX_N + 1]) -> Int64:
    var left = start_input
    var right = end_input
    var left_hash: Int64 = 0
    var right_hash: Int64 = 0
    var right_length = 0
    while left < right:
        if left % 2 == 1:
            left_hash = rht_concat(left_hash, tree_hash[left],
                tree_length[left], powers)
            left += 1
        if right % 2 == 1:
            right -= 1
            right_hash = rht_concat(tree_hash[right], right_hash,
                right_length, powers)
            right_length += tree_length[right]
        left //= 2
        right //= 2
    return rht_concat(left_hash, right_hash, right_length, powers)

@export("rolling_hash_on_segment_tree_trace")
fn rolling_hash_on_segment_tree_trace(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PARSEABLE_INPUT:
        return -1
    let raw_n = input[0]
    let raw_q = input[1]
    if raw_n < 0 or raw_n > MAX_N or raw_q < 0 or raw_q > MAX_Q: return -1
    let n = Int(raw_n)
    let q = Int(raw_q)
    if length != c_size_t(2 + n + 5 * q): return -1

    var powers = InlineArray[Int64, MAX_N + 1](fill=0)
    powers[0] = 1
    for exponent in range(MAX_N):
        powers[exponent + 1] = (powers[exponent] * HASH_BASE) % MODULUS
    var tree_hash = InlineArray[Int64, TREE_SIZE](fill=0)
    var tree_length = InlineArray[Int, TREE_SIZE](fill=0)
    for index in range(n):
        let symbol = input[2 + index]
        if symbol < 0 or symbol > 25: return -1
        let leaf = TREE_BASE + index
        tree_hash[leaf] = symbol
        tree_length[leaf] = 1
    var node = TREE_BASE - 1
    while node > 0:
        rht_pull(inout tree_hash, inout tree_length, node, powers)
        node -= 1

    var score: Int64 = 0
    for operation in range(q):
        let record = 2 + n + 5 * operation
        let opcode = input[record]
        let a_value = input[record + 1]
        let b_value = input[record + 2]
        let c_value = input[record + 3]
        let d_value = input[record + 4]
        var response: Int64 = 0

        if opcode == 0:
            if a_value < 0 or a_value >= raw_n or b_value < 0 or b_value > 25 or c_value != 0 or d_value != 0:
                return -1
            var leaf = TREE_BASE + Int(a_value)
            tree_hash[leaf] = b_value
            tree_length[leaf] = 1
            while leaf > 1:
                leaf //= 2
                rht_pull(inout tree_hash, inout tree_length, leaf, powers)
        elif opcode == 1:
            if a_value < 0 or a_value > raw_n or b_value < 0 or b_value > raw_n or
               c_value < 0 or c_value > raw_n or d_value < 0 or d_value > raw_n or
               a_value > b_value or c_value > d_value:
                return -1
            if b_value - a_value == d_value - c_value:
                let first = rht_hash_range(tree_hash, tree_length,
                    TREE_BASE + Int(a_value), TREE_BASE + Int(b_value), powers)
                let second = rht_hash_range(tree_hash, tree_length,
                    TREE_BASE + Int(c_value), TREE_BASE + Int(d_value), powers)
                response = 1 if first == second else 0
            else:
                response = 0
        else:
            return -1

        let token = opcode * 2 + response + 1
        score += Int64(operation + 1) * token
    return score
