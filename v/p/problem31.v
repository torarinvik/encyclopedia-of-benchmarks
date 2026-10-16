module problem31

const max_target = 500
const coins = [8]i64{1, 2, 5, 10, 20, 50, 100, 200}

@[export: 'problem31']
pub fn problem31(target i64) i64 {
	if target < 0 || target > max_target { return -1 }
	mut ways := [max_target + 1]i64{}
	ways[0] = 1
	for coin in coins {
		mut amount := int(coin)
		for amount <= int(target) {
			ways[amount] += ways[amount - int(coin)]
			amount++
		}
	}
	return ways[int(target)]
}
