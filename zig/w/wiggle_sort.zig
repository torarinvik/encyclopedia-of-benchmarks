const std=@import("std");
const MAX_ARRAY_LENGTH:usize=4096;

export fn wiggle_sort(input:[*]const i64,length:usize,output:[*]u8,output_capacity:usize)i64{
    if(length>MAX_ARRAY_LENGTH)return -1;
    var values:[MAX_ARRAY_LENGTH]i64=@splat(0);
    for(0..length)|i|{if(valuesOutOfRange(input[i]))return -1;values[i]=input[i];}
    const bytes=length*4;if(output_capacity<bytes)return -2;
        var i:usize=1;while(i<length):(i+=1){if((i%2==1 and values[i-1]>values[i])or(i%2==0 and values[i-1]<values[i])){const t=values[i];values[i]=values[i-1];values[i-1]=t;}}

    for(0..length)|out_index|{const bits:u32=@bitCast(@as(i32,@intCast(values[out_index])));for(0..4)|byte_index|output[out_index*4+byte_index]=@truncate(bits>>@intCast(byte_index*8));}
    return @intCast(length);
}
fn valuesOutOfRange(value:i64)bool{return value<@as(i64,std.math.minInt(i32)) or value>@as(i64,std.math.maxInt(i32));}
