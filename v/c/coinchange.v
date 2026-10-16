module main

const max_amount = 30
const max_coins = 8

@[export: 'coinchange']
pub fn coinchange(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > max_coins + 2 { return -1 }
		amount_value := values[0]
		coin_count_value := values[1]
		if amount_value < 1 || amount_value > max_amount || coin_count_value < 0 || coin_count_value > max_coins { return -1 }
		amount := int(amount_value)
		coin_count := int(coin_count_value)
		if int(length) != coin_count + 2 { return -1 }
		for index in 0 .. coin_count {
			if values[index + 2] < 1 || values[index + 2] > max_amount { return -1 }
		}

		mut combinations := [max_amount]i64{}
		combinations[0] = 1
		for coin_index in 0 .. coin_count {
			coin := int(values[coin_index + 2])
			for subtotal in coin .. amount {
				combinations[subtotal] += combinations[subtotal - coin]
			}
		}
		return combinations[amount - 1]
	}
}
