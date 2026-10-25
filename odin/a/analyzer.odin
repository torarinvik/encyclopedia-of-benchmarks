package analyzer

import "core:c"

MAX_EVENTS :: 64
MAX_EPOCH :: i64(15)
MAX_ADDRESS :: i64(255)

@(export)
analyzer :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 194 do return -1
    count_value := input[0]
    if count_value < 0 || count_value > MAX_EVENTS do return -1
    count := int(count_value)
    if length != c.size_t(1 + 3 * count) do return -1
    latest_writer: [256]i64
    for address in 0..<256 do latest_writer[address] = -1
    conflicts: i64 = 0
    previous_epoch: i64 = 0
    for event in 0..<count {
        base := 1 + 3 * event
        epoch, opcode, address_value := input[base], input[base+1], input[base+2]
        if epoch < previous_epoch || epoch < 0 || epoch > MAX_EPOCH
            || (opcode != 0 && opcode != 1) || address_value < 0 || address_value > MAX_ADDRESS do return -1
        previous_epoch = epoch
        address := int(address_value)
        if opcode == 0 {
            latest_writer[address] = i64(event)
        } else {
            for prior in 0..<event {
                prior_base := 1 + 3 * prior
                if input[prior_base] < epoch && input[prior_base+1] == 0
                    && input[prior_base+2] == address_value && latest_writer[address] == i64(prior) {
                    conflicts += 1
                }
            }
        }
    }
    return conflicts
}
