const MAX_N: usize = 4;
const MAX_CELLS: usize = 64;
const MAX_MOVES: usize = 48;
const MAX_WORDS: usize = 66;

const Move = struct { i: usize, j: usize, k: usize, ip: usize, jp: usize, kp: usize };

fn at(n: usize, i: usize, j: usize, k: usize) usize { return (i*n+j)*n+k; }

fn selectMove(tensor: *const [MAX_CELLS]i64, n: usize, choice: usize) ?Move {
    var moves = [_]Move{.{.i=0,.j=0,.k=0,.ip=0,.jp=0,.kp=0}} ** MAX_MOVES;
    var defects: usize = 0;
    var pi: usize = 0; var pj: usize = 0; var pk: usize = 0; var count: usize = 0;
    for (0..n) |i| for (0..n) |j| for (0..n) |k| {
        if (tensor[at(n,i,j,k)] == -1) { defects += 1; pi=i; pj=j; pk=k; }
    };
    if (defects > 1) return null;
    if (defects == 1) {
        for (0..n) |ip| for (0..n) |jp| for (0..n) |kp| {
            if (ip!=pi and jp!=pj and kp!=pk and tensor[at(n,pi,pj,kp)]==1 and
                tensor[at(n,pi,jp,pk)]==1 and tensor[at(n,ip,pj,pk)]==1) {
                moves[count]=.{.i=pi,.j=pj,.k=pk,.ip=ip,.jp=jp,.kp=kp}; count+=1;
            }
        };
        if (count != 8) return null;
    } else {
        for (0..n) |i| for (0..n) |j| for (0..n) |k| {
            if (tensor[at(n,i,j,k)] != 0) continue;
            var ip=n; var jp=n; var kp=n;
            for (0..n) |x| { if (tensor[at(n,x,j,k)]==1) ip=x; }
            for (0..n) |x| { if (tensor[at(n,i,x,k)]==1) jp=x; }
            for (0..n) |x| { if (tensor[at(n,i,j,x)]==1) kp=x; }
            if (ip==n or jp==n or kp==n) return null;
            moves[count]=.{.i=i,.j=j,.k=k,.ip=ip,.jp=jp,.kp=kp}; count+=1;
        };
        if (count != n*n*n-n*n) return null;
    }
    if (choice >= count) return null;
    return moves[choice];
}

fn applyChoice(tensor: *[MAX_CELLS]i64, n: usize, choice: usize) bool {
    const m = selectMove(tensor,n,choice) orelse return false;
    tensor[at(n,m.i,m.j,m.k)] += 1;
    tensor[at(n,m.ip,m.jp,m.k)] += 1;
    tensor[at(n,m.ip,m.j,m.kp)] += 1;
    tensor[at(n,m.i,m.jp,m.kp)] += 1;
    tensor[at(n,m.ip,m.j,m.k)] -= 1;
    tensor[at(n,m.i,m.jp,m.k)] -= 1;
    tensor[at(n,m.i,m.j,m.kp)] -= 1;
    tensor[at(n,m.ip,m.jp,m.kp)] -= 1;
    return true;
}

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset+byte] = @truncate(bits >> @as(u6,@intCast(byte*8)));
}

export fn jacobson_matthews_latin_square_chain(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 14) return -1;
    const values = input.?;
    const nv=values[0]; const sv=values[1];
    if (nv<2 or nv>@as(i64,@intCast(MAX_N)) or sv<0 or sv>12 or length!=2+@as(usize,@intCast(sv))) return -1;
    const n: usize=@intCast(nv); const steps: usize=@intCast(sv);
    var tensor=[_]i64{0} ** MAX_CELLS;
    for (0..n) |i| for (0..n) |j| { tensor[at(n,i,j,(i+j)%n)]=1; };
    for (0..steps) |step| {
        const choice=values[2+step];
        if (choice<0 or choice>=@as(i64,@intCast(MAX_MOVES)) or !applyChoice(&tensor,n,@intCast(choice))) return -1;
    }
    const word_count=2+n*n*n; const bytes=word_count*8;
    if (output==null or capacity<bytes) return -2;
    var words=[_]i64{0} ** MAX_WORDS;
    words[0]=nv; words[1]=sv;
    for (0..n*n*n) |i| words[2+i]=tensor[i];
    const out=output.?[0..bytes];
    for (0..word_count) |i| writeI64Le(out,i*8,words[i]);
    return @intCast(bytes);
}
