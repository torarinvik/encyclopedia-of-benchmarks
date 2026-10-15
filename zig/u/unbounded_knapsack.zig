const MAX_ITEMS: usize = 16;
const MAX_CAPACITY: usize = 100;

fn solve(item: usize, capacity: usize, values: []const i64, weights: []const i64, memo: *[MAX_ITEMS][MAX_CAPACITY + 1]i64) i64 {
    if (item == 0) return @as(i64, @intCast(capacity)) / weights[0] * values[0];
    if (memo[item][capacity] >= 0) return memo[item][capacity];
    const skip = solve(item - 1, capacity, values, weights, memo);
    var take: i64 = 0;
    if (@as(i64, @intCast(capacity)) >= weights[item]) take = values[item] + solve(item, capacity - @as(usize, @intCast(weights[item])), values, weights, memo);
    memo[item][capacity] = @max(take, skip);
    return memo[item][capacity];
}

/// Solve the unbounded knapsack recurrence for positive item values and weights.
export fn unbounded_knapsack(input: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const v=input[0..length];
    if(v[0]<0 or v[0]>16 or v[1]<0 or v[1]>100)return -1;
    const n:usize=@intCast(v[0]);const capacity:usize=@intCast(v[1]);
    if(length!=2+2*n)return -1;
    if(n==0)return 0;
    const values=v[2..2+n];const weights=v[2+n..2+2*n];
    for(values)|x|{if(x<1 or x>100)return -1;}
    for(weights)|x|{if(x<1 or x>100)return -1;}
    var memo=[_] [MAX_CAPACITY+1]i64{[_]i64{-1}**(MAX_CAPACITY+1)}**MAX_ITEMS;
    return solve(n-1,capacity,values,weights,&memo);
}
