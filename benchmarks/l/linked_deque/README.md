# Linked deque

The pinned Lua structure is a doubly linked deque with push, pop, get, and empty operations at both ends. Popping or getting an empty deque returns nil; push inserts at the named end. This bounded operation-trace contract packs query results in order.

## Contract

Input is up to ten [operation,argument] pairs: 0 push_head, 1 push_tail, 2 pop_head, 3 pop_tail, 4 get_head, 5 get_tail, 6 empty. Push values are in [-15,15]; other operation arguments must be zero. Output is base-32 digits in event order, least significant first: nil=0, a value v is v+16, empty=true is 1, empty=false is 2. Invalid input returns -1.

See [workload](workload.json), [oracle](../../linked_deque_oracle.py), and pinned [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/linked_deque.lua). The workload includes malformed operation arrays and a maximum-length trace. `benchmarks/verify_linked_deque.py` checks all nine ports against the operation-trace oracle and recorder.

| Language | Port |
|---|---|
| C | [c/l/linked_deque.c](../../../c/l/linked_deque.c) |
| C3 | [c3/l/linked_deque.c3](../../../c3/l/linked_deque.c3) |
| C++ | [c++/l/linked_deque.cpp](../../../cpp/l/linked_deque.cpp) |
| Elisa | [elisa/l/linked_deque.elisa](../../../elisa/l/linked_deque.elisa) |
| Nim | [nim/l/linked_deque.nim](../../../nim/l/linked_deque.nim) |
| Odin | [odin/l/linked_deque.odin](../../../odin/l/linked_deque.odin) |
| Rust | [rust/l/linked_deque.rs](../../../rust/l/linked_deque.rs) |
| V | [v/l/linked_deque.v](../../../v/l/linked_deque.v) |
| Zig | [zig/l/linked_deque.zig](../../../zig/l/linked_deque.zig) |
