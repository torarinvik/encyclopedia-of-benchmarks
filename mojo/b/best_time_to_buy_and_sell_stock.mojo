from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("best_time_to_buy_and_sell_stock")
fn best_time_to_buy_and_sell_stock(prices: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096: return -1
    if length == 0: return 0
    if prices == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    var minimum = prices[0]
    var best: Int64 = 0
    for i in range(Int(length)):
        let price = prices[i]
        if price < 0 or price > 1_000_000_000: return -1
        minimum = min(minimum, price)
        best = max(best, price - minimum)
    return best
