from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 512
alias MODULUS = 998244353

fn mod_pow(base_value: Int64, exponent_value: Int) -> Int64:
    var result: Int64 = 1
    var base = base_value
    var exponent = exponent_value
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result

fn solve(n: Int) -> Int64:
    var factorial = InlineArray[Int64, MAX_N + 1]()
    var inverse_factorial = InlineArray[Int64, MAX_N + 1]()
    var all_graphs = InlineArray[Int64, MAX_N + 1]()
    var connected = InlineArray[Int64, MAX_N + 1]()
    factorial[0] = 1
    for i in range(1, n + 1):
        factorial[i] = factorial[i - 1] * i % MODULUS
    inverse_factorial[n] = mod_pow(factorial[n], 998244351)
    for i in range(n, 0, -1):
        inverse_factorial[i - 1] = inverse_factorial[i] * i % MODULUS

    all_graphs[0] = 1
    var edge_choices: Int64 = 1
    for size in range(1, n + 1):
        all_graphs[size] = all_graphs[size - 1] * edge_choices % MODULUS
        edge_choices = edge_choices * 2 % MODULUS
    connected[1] = 1
    for size in range(2, n + 1):
        var disconnected: Int64 = 0
        for component_size in range(1, size):
            var choose = factorial[size - 1] * inverse_factorial[component_size - 1] % MODULUS
            choose = choose * inverse_factorial[size - component_size] % MODULUS
            var term = choose * connected[component_size] % MODULUS
            term = term * all_graphs[size - component_size] % MODULUS
            disconnected = (disconnected + term) % MODULUS
        connected[size] = (all_graphs[size] - disconnected + MODULUS) % MODULUS
    return connected[n]

@export("connected_labeled_graph_count")
fn connected_labeled_graph_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1
    if input[0] < 1 or input[0] > MAX_N:
        return -1
    return solve(Int(input[0]))
