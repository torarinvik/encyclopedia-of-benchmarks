module richest_customer_wealth

const max_rows = 32
const max_columns = 32
const max_input_length = 1027
const max_amount = i64(1_000_000)

@[export: 'richest_customer_wealth']
pub fn richest_customer_wealth(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
    unsafe {
        if input[0] < 1 || input[0] > max_rows || input[1] < 1 || input[1] > max_columns { return -1 }
        rows := int(input[0])
        columns := int(input[1])
        if length != usize(2 + rows * columns) { return -1 }
        mut richest := i64(0)
        for row in 0 .. rows {
            mut wealth := i64(0)
            for column in 0 .. columns {
                amount := input[2 + row * columns + column]
                if amount < 0 || amount > max_amount { return -1 }
                wealth += amount
            }
            if wealth > richest { richest = wealth }
        }
        return richest
    }
}
