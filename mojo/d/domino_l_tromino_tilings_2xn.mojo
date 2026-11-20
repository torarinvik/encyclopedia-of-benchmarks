from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_WIDTH = 32
const MAX_INPUT_LENGTH = 2

fn count_tilings(width: Int64) -> Int64:
    var state0: Int64 = 1
    var state1: Int64 = 0
    var state2: Int64 = 0
    var state3: Int64 = 0
    for _ in range(Int(width)):
        let next0 = state0 + state3
        let next1 = state0 + state2
        let next2 = state0 + state1
        let next3 = state0 + state1 + state2
        state0 = next0
        state1 = next1
        state2 = next2
        state3 = next3
    return state0

@export("domino_l_tromino_tilings_2xn")
fn domino_l_tromino_tilings_2xn(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    if length != 1 or input[0] < 0 or input[0] > MAX_WIDTH: return -1
    return count_tilings(input[0])
