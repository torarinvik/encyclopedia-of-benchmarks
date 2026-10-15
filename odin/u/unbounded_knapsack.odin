package unbounded_knapsack
import "core:c"
MAX_ITEMS :: 16
MAX_CAPACITY :: 100

solve :: proc(item, capacity: int, values, weights: [^]i64, memo: ^[MAX_ITEMS][MAX_CAPACITY+1]i64) -> i64 {
	if item == 0 do return i64(capacity) / weights[0] * values[0]
	if memo[item][capacity] >= 0 do return memo[item][capacity]
	skip := solve(item-1,capacity,values,weights,memo)
	take: i64 = 0
	if i64(capacity) >= weights[item] do take = values[item] + solve(item,capacity-int(weights[item]),values,weights,memo)
	if take > skip do memo[item][capacity] = take else memo[item][capacity] = skip
	return memo[item][capacity]
}

// Solve unbounded knapsack with the source's take-again or skip-previous recurrence.
@(export)
unbounded_knapsack :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	if input[0] < 0 || input[0] > MAX_ITEMS || input[1] < 0 || input[1] > MAX_CAPACITY do return -1
	n := int(input[0]); capacity := int(input[1])
	if length != c.size_t(2+2*n) do return -1
	if n == 0 do return 0
	values := input+2; weights := input+2+n
	for i:=0;i<n;i+=1 { if values[i]<1||values[i]>100||weights[i]<1||weights[i]>100 do return -1 }
	var memo: [MAX_ITEMS][MAX_CAPACITY+1]i64
	for i:=0;i<MAX_ITEMS;i+=1 { for c:=0;c<=MAX_CAPACITY;c+=1 { memo[i][c]=-1 } }
	return solve(n-1,capacity,values,weights,&memo)
}
