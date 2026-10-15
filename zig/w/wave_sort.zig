const std=@import("std");
const MAX_ARRAY_LENGTH:usize=4096;
fn sift_down(v:[]i64,root_input:usize,end:usize)void{var root=root_input;while(root<end/2){var child=root*2+1;if(child+1<end and v[child]<v[child+1])child+=1;if(v[root]>=v[child])break;const t=v[root];v[root]=v[child];v[child]=t;root=child;}}

export fn wave_sort(input:[*]const i64,length:usize,output:[*]u8,output_capacity:usize)i64{
    if(length>MAX_ARRAY_LENGTH)return -1;
    var values:[MAX_ARRAY_LENGTH]i64=@splat(0);
    for(0..length)|i|{if(valuesOutOfRange(input[i]))return -1;values[i]=input[i];}
    const bytes=length*4;if(output_capacity<bytes)return -2;
        for(0..length/2)|offset|{const start=length/2-1-offset;sift_down(values[0..length],start,length);}
    var end=length;while(end>1){const t=values[0];values[0]=values[end-1];values[end-1]=t;end-=1;sift_down(values[0..length],0,end);}
    var i:usize=0;while(i+1<length):(i+=2){const t=values[i];values[i]=values[i+1];values[i+1]=t;}

    for(0..length)|out_index|{const bits:u32=@bitCast(@as(i32,@intCast(values[out_index])));for(0..4)|byte_index|output[out_index*4+byte_index]=@truncate(bits>>@intCast(byte_index*8));}
    return @intCast(length);
}
fn valuesOutOfRange(value:i64)bool{return value<@as(i64,std.math.minInt(i32)) or value>@as(i64,std.math.maxInt(i32));}
