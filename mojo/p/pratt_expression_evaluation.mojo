from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime PRATT_INVALID_RESULT: Int64 = -9223372036854775807 - 1
comptime PRATT_MAX_TOKENS = 15

@fieldwise_init
struct PrattParser(Copyable):
    var input: UnsafePointer[Int64, ImmutAnyOrigin]
    var count: Int
    var position: Int
    var invalid: Bool

    fn parse(mut self, minimum_binding_power: Int) -> Int64:
        if self.position >= self.count:
            self.invalid = True
            return 0
        let offset = 1 + 2 * self.position
        self.position += 1
        let kind = self.input[offset]
        var left = Int64(0)
        if kind == 1:
            left = self.input[offset + 1]
        elif kind == 3:
            left = -self.parse(25)
        elif kind == 5:
            left = self.parse(0)
            if self.invalid or self.position >= self.count or self.input[1 + 2 * self.position] != 6:
                self.invalid = True
                return 0
            self.position += 1
        else:
            self.invalid = True
            return 0
        if self.invalid:
            return 0

        while self.position < self.count:
            let op = self.input[1 + 2 * self.position]
            var binding_power = -1
            if op == 2 or op == 3:
                binding_power = 10
            elif op == 4:
                binding_power = 20
            if binding_power < minimum_binding_power:
                break
            self.position += 1
            let right = self.parse(binding_power + 1)
            if self.invalid:
                return 0
            if op == 2:
                left += right
            elif op == 3:
                left -= right
            else:
                left *= right
        return left

@export("pratt_expression_evaluation")
fn pratt_expression_evaluation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 32:
        return PRATT_INVALID_RESULT
    let raw_count = input[0]
    if raw_count < 1 or raw_count > PRATT_MAX_TOKENS:
        return PRATT_INVALID_RESULT
    let count = Int(raw_count)
    if length != c_size_t(1 + 2 * count):
        return PRATT_INVALID_RESULT
    for token in range(count):
        let kind = input[1 + 2 * token]
        let payload = input[2 + 2 * token]
        if kind == 1:
            if payload < 0 or payload > 9:
                return PRATT_INVALID_RESULT
        elif kind >= 2 and kind <= 6:
            if payload != 0:
                return PRATT_INVALID_RESULT
        else:
            return PRATT_INVALID_RESULT
    var parser = PrattParser(input, count, 0, False)
    let result = parser.parse(0)
    if parser.invalid or parser.position != count:
        return PRATT_INVALID_RESULT
    return result
