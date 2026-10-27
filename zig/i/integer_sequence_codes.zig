const MaxN: usize = 32;
const MaxInput: usize = 35;
const MaxOutput: usize = 4096;
const MaxResult: usize = 512;

fn bit(out: *[MaxOutput]u8, used: *usize, value: bool) void {
    out[used.*] = if (value) '1' else '0';
    used.* += 1;
}
fn rawByte(out: *[MaxOutput]u8, used: *usize, value: u8) void { out[used.*] = value; used.* += 1; }
fn number(out: *[MaxOutput]u8, used: *usize, value: u64, width: i32) void {
    var shift = width;
    while (shift > 0) {
        shift -= 1;
        bit(out, used, ((value >> @intCast(shift)) & 1) != 0);
    }
}
fn unary(out: *[MaxOutput]u8, used: *usize, value: u64) void {
    var i: u64 = 0;
    while (i < value) : (i += 1) bit(out, used, true);
    bit(out, used, false);
}
fn floorLog2(value: u64) i32 {
    var remaining = value;
    var width: i32 = -1;
    while (remaining != 0) : (remaining >>= 1) width += 1;
    return width;
}
fn minimal(out: *[MaxOutput]u8, used: *usize, value: u64, universe: u64) void {
    if (universe == 1) return;
    const low_width = floorLog2(universe);
    const short_count = (@as(u64, 1) << @intCast(low_width + 1)) - universe;
    if (value < short_count) number(out, used, value, low_width)
    else number(out, used, value + short_count, low_width + 1);
}
fn gamma(out: *[MaxOutput]u8, used: *usize, value: u64) void {
    const shifted = value + 1;
    const width = floorLog2(shifted);
    unary(out, used, @intCast(width));
    number(out, used, shifted - (@as(u64, 1) << @intCast(width)), width);
}
fn delta(out: *[MaxOutput]u8, used: *usize, value: u64) void {
    const shifted = value + 1;
    const width = floorLog2(shifted);
    gamma(out, used, @intCast(width));
    number(out, used, shifted - (@as(u64, 1) << @intCast(width)), width);
}
fn interpolative(out: *[MaxOutput]u8, used: *usize, values: []const i64,
                 left: usize, right: usize, low: i64, high: i64) void {
    if (left >= right) return;
    const middle = left + (right - left - 1) / 2;
    const value = values[middle];
    const lower = low + @as(i64, @intCast(middle - left));
    const upper = high - @as(i64, @intCast(right - middle - 1));
    minimal(out, used, @intCast(value - lower), @intCast(upper - lower));
    interpolative(out, used, values, left, middle, low, value);
    interpolative(out, used, values, middle + 1, right, value + 1, high);
}
fn simple9(out: *[MaxOutput]u8, used: *usize, values: []const i64) void {
    const slots=[_]usize{28,14,9,7,5,4,3,2,1};
    const widths=[_]u6{1,2,3,4,5,7,9,14,28};
    var position:usize=0;
    while(position<values.len){
        var selector:usize=0;var take:usize=0;
        for(0..9)|s|{
            const count=@min(slots[s],values.len-position);var fits=true;
            for(0..count)|j|if(@as(u64,@intCast(values[position+j]))>=(@as(u64,1)<<widths[s])){fits=false;};
            if(fits){selector=s;take=count;break;}
        }
        const width:usize=widths[selector];var word=@as(u64,@intCast(selector))<<28;
        for(0..take)|j|{word|=@as(u64,@intCast(values[position+j]))<<@intCast(28-width*(j+1));}
        number(out,used,word,32);position+=take;
    }
}

export fn integer_sequence_codes(input_opt: ?[*]const i64, length: usize,
                                 output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MaxInput) return -1;
    const input = input_opt.?;
    const mode = input[0];
    const n0 = input[1];
    const parameter = input[2];
    if (mode < 0 or mode > 9 or n0 < 1 or n0 > MaxN or length != @as(usize, @intCast(n0)) + 3) return -1;
    const n: usize = @intCast(n0);
    const values = input[3 .. 3 + n];
    if (mode == 0) {
        if (parameter != 0) return -1;
        for (values) |value| if (value < 0 or value > 31) return -1;
    } else if (mode == 1) {
        if (parameter < 2 or parameter > 1000000) return -1;
        for (values) |value| if (value < 0 or value >= parameter) return -1;
    } else if (mode == 2 or mode == 3) {
        if (parameter != 0) return -1;
        for (values) |value| if (value < 0 or value > 1000000) return -1;
    } else if (mode == 4) {
        if (parameter < 1 or parameter > 128) return -1;
        for (values) |value| if (value < 0 or value > 127) return -1;
    } else if (mode == 7) {
        if (parameter != 0) return -1;
        for (values) |value| if (value < 0 or value > 1000000) return -1;
    } else if (mode == 8) {
        if (parameter != 0) return -1;
        for (values) |value| if (value < 0 or value >= (@as(i64,1)<<28)) return -1;
    } else if (mode == 9) {
        if (parameter < 1 or parameter > 20) return -1;
        for (values) |value| if (value < 0 or value > 1000000) return -1;
    } else {
        if (parameter < 2 or parameter > 4096 or n0 > parameter) return -1;
        for (values, 0..) |value, index| {
            if (value < 0 or value >= parameter or (index > 0 and values[index - 1] >= value)) return -1;
        }
    }
    var staged: [MaxOutput]u8 = @splat(0);
    var used: usize = 0;
    if (mode == 0) {
        for (values) |value| unary(&staged, &used, @intCast(value));
    } else if (mode == 1) {
        for (values) |value| minimal(&staged, &used, @intCast(value), @intCast(parameter));
    } else if (mode == 2) {
        for (values) |value| gamma(&staged, &used, @intCast(value));
    } else if (mode == 3) {
        for (values) |value| delta(&staged, &used, @intCast(value));
    } else if (mode == 4) {
        const b: u64 = @intCast(parameter);
        for (values) |value| {
            const x: u64 = @intCast(value);
            unary(&staged, &used, x / b);
            minimal(&staged, &used, x % b, b);
        }
    } else if (mode == 5) {
        var width: usize = 0;
        while (@as(u64, @intCast(n)) * (@as(u64, 1) << @intCast(width + 1)) <= @as(u64, @intCast(parameter))) width += 1;
        const bucket_size: u64 = @as(u64, 1) << @intCast(width);
        const buckets: usize = @intCast((@as(u64, @intCast(parameter)) + bucket_size - 1) / bucket_size);
        var counts: [4096]u8 = @splat(0);
        for (values) |value| counts[@intCast(@as(u64, @intCast(value)) / bucket_size)] += 1;
        for (0..buckets) |bucket| unary(&staged, &used, counts[bucket]);
        for (values) |value| number(&staged, &used, @as(u64, @intCast(value)) % bucket_size, @intCast(width));
    } else if (mode == 6) {
        interpolative(&staged, &used, values, 0, n, 0, parameter);
    } else if (mode == 7) {
        for(values)|value|{
            const x:u64=@intCast(value);var highest=floorLog2(x);if(highest<0){highest=0;}else{highest=(highest/7)*7;}
            var shift=highest;while(shift>=0){var byte:u8=@truncate((x>>@intCast(shift))&0x7f);if(shift!=0){byte|=0x80;}rawByte(&staged,&used,byte);shift-=7;}
        }
    } else if (mode == 8) {
        simple9(&staged,&used,values);
    } else {
        const width:u6=@intCast(parameter);const mask=(@as(u64,1)<<width)-1;var exception_count:u64=0;
        for(values)|value|{const x:u64=@intCast(value);number(&staged,&used,x&mask,@intCast(width));if(x>=(@as(u64,1)<<width)){exception_count+=1;}}
        number(&staged,&used,exception_count,6);
        var position_width:u6=0;while((@as(usize,1)<<position_width)<n){position_width+=1;}
        for(values,0..)|value,index|{const x:u64=@intCast(value);if(x>=(@as(u64,1)<<width)){number(&staged,&used,@intCast(index),@intCast(position_width));number(&staged,&used,x,20);}}
    }
    if(output_opt==null)return -2;
    if(mode==7){if(capacity<used)return -2;@memcpy(output_opt.?[0..used],staged[0..used]);return @intCast(used);}
    const bytes=(used+7)/8;if(capacity<bytes)return -2;var packed:[MaxResult]u8=@splat(0);
    for(0..used)|i|if(staged[i]=='1'){packed[i/8]|=@as(u8,1)<<@intCast(7-i%8);};
    @memcpy(output_opt.?[0..bytes],packed[0..bytes]);return @intCast(bytes);
}
