from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = Int64(1_000_000)
comptime MAX_ROOT = 1_000
comptime MAX_PRIMES = 168

struct PowerfulState:
    var n: Int64
    var total: Int64
    var prime_count: Int
    var primes: InlineArray[Int64, MAX_PRIMES]

    fn __init__(out self):
        self.n = 0
        self.total = 0
        self.prime_count = 0
        self.primes = InlineArray[Int64, MAX_PRIMES](fill=0)

fn powerful_enumerate(inout state: PowerfulState, start: Int,
        current: Int64, current_h: Int64):
    let remaining = state.n / current
    var prime_index = start
    while prime_index < state.prime_count:
        let prime = state.primes[prime_index]
        if prime > remaining / prime:
            break
        var prime_power = prime * prime
        var h_power = prime - 1
        while prime_power <= remaining:
            let powerful = current * prime_power
            let h_value = current_h * h_power
            state.total += h_value * (state.n / powerful)
            powerful_enumerate(state, prime_index + 1, powerful, h_value)
            if prime_power > remaining / prime:
                break
            prime_power *= prime
            h_power *= prime
        prime_index += 1

@export("powerful_number_summatory_sieve")
fn powerful_number_summatory_sieve(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1
    let n = input[0]
    if n < 1 or n > MAX_N:
        return -1

    var root: Int64 = 1
    while root + 1 <= n / (root + 1):
        root += 1

    var composite = InlineArray[Bool, MAX_ROOT + 1](fill=False)
    var state = PowerfulState()
    state.n = n
    state.total = n
    var candidate = 2
    while candidate <= Int(root):
        if not composite[candidate]:
            state.primes[state.prime_count] = Int64(candidate)
            state.prime_count += 1
            if candidate <= Int(root) / candidate:
                var multiple = candidate * candidate
                while multiple <= Int(root):
                    composite[multiple] = True
                    multiple += candidate
        candidate += 1

    powerful_enumerate(state, 0, 1, 1)
    return state.total
