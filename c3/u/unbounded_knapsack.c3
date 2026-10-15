module unbounded_knapsack;
const usz MAX_ITEMS = 16, MAX_CAPACITY = 100;

fn long solve(usz item, usz capacity, long* values, long* weights, long[16][101]* memo)
{
    if (item == 0) return (long)(capacity / (usz)weights[0]) * values[0];
    if (memo[item][capacity] >= 0) return memo[item][capacity];
    long skip = solve(item - 1, capacity, values, weights, memo);
    long take = 0;
    if ((long)capacity >= weights[item]) take = values[item] + solve(item, capacity - (usz)weights[item], values, weights, memo);
    memo[item][capacity] = take > skip ? take : skip;
    return memo[item][capacity];
}

fn long unbounded_knapsack_impl(long* input, usz length)
{
    if (input == null || length < 2) return -1;
    long nv=input[0], cv=input[1]; if(nv<0||nv>16||cv<0||cv>100)return -1;
    usz n=(usz)nv,capacity=(usz)cv; if(length!=2+2*n)return -1;
    if(n==0)return 0;
    long* values=input+2; long* weights=input+2+n;
    for(usz i=0;i<n;i++)if(values[i]<1||values[i]>100||weights[i]<1||weights[i]>100)return -1;
    long[16][101] memo=zeroed;
    for(usz i=0;i<16;i++)for(usz c=0;c<=100;c++)memo[i][c]=-1;
    return solve(n-1,capacity,values,weights,&memo);
}
fn long unbounded_knapsack(long* input, usz length) @export("unbounded_knapsack") { return unbounded_knapsack_impl(input,length); }
