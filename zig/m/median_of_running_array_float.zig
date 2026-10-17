const std = @import("std");

const MAX_COUNT = 64;
const MAX_INPUT_LENGTH = 66;

fn lessFloat(left: f32, right: f32) bool {
    if (left < right) return true;
    if (left == 0.0 and right == 0.0) return @as(u32, @bitCast(left)) >> 31 != 0 and @as(u32, @bitCast(right)) >> 31 == 0;
    return false;
}
fn pushMax(heap: *[MAX_COUNT]f32, count: *usize, value: f32) void { var p=count.*;count.*+=1;while(p>0 and lessFloat(heap[(p-1)/2],value)){const parent=(p-1)/2;heap[p]=heap[parent];p=parent;}heap[p]=value; }
fn popMax(heap: *[MAX_COUNT]f32, count: *usize) f32 { const result=heap[0];count.*-=1;const value=heap[count.*];if(count.*==0)return result;var p:usize=0;while(2*p+1<count.*){var child=2*p+1;if(child+1<count.* and lessFloat(heap[child],heap[child+1]))child+=1;if(!lessFloat(value,heap[child]))break;heap[p]=heap[child];p=child;}heap[p]=value;return result; }
fn pushMin(heap: *[MAX_COUNT]f32, count: *usize, value: f32) void { var p=count.*;count.*+=1;while(p>0 and lessFloat(value,heap[(p-1)/2])){const parent=(p-1)/2;heap[p]=heap[parent];p=parent;}heap[p]=value; }
fn popMin(heap: *[MAX_COUNT]f32, count: *usize) f32 { const result=heap[0];count.*-=1;const value=heap[count.*];if(count.*==0)return result;var p:usize=0;while(2*p+1<count.*){var child=2*p+1;if(child+1<count.* and lessFloat(heap[child+1],heap[child]))child+=1;if(!lessFloat(heap[child],value))break;heap[p]=heap[child];p=child;}heap[p]=value;return result; }

export fn median_of_running_array_float(input_opt: ?[*]const f64, length: usize,
                                        output_opt: ?[*]f64, capacity: usize) i64 {
    if(input_opt==null or length<1 or length>MAX_INPUT_LENGTH)return -1;
    const input=input_opt.?;const count_value=input[0];
    if(!std.math.isFinite(count_value)||count_value<1.0 or count_value>MAX_COUNT or @trunc(count_value)!=count_value or length!=1+@as(usize,@intFromFloat(count_value)))return -1;
    const count:usize=@intFromFloat(count_value);var lower:[MAX_COUNT]f32=@splat(0.0);var upper:[MAX_COUNT]f32=@splat(0.0);var medians:[MAX_COUNT]f32=@splat(0.0);var lc:usize=0;var uc:usize=0;
    for(0..count)|i|{const sample=input[i+1];if(!std.math.isFinite(sample) or sample < -1_000_000.0 or sample>1_000_000.0)return -1;const x:f32=@floatCast(sample);if(@as(f64,x)!=sample or (sample==0.0 and (@as(u64,@bitCast(sample))>>63)!=@as(u64,@as(u32,@bitCast(x))>>31)))return -1;
        if(uc>0 and lessFloat(x,upper[0]))pushMax(&lower,&lc,x)else pushMin(&upper,&uc,x);
        if(lc>uc+1)pushMin(&upper,&uc,popMax(&lower,&lc))else if(uc>lc+1)pushMax(&lower,&lc,popMin(&upper,&uc));
        if(lc>uc)medians[i]=lower[0]else if(uc>lc)medians[i]=upper[0]else{const sum:f32=lower[0]+upper[0];const average:f32=sum/2.0;medians[i]=average;}}
    if(output_opt==null or capacity<count)return -2;const output=output_opt.?;for(0..count)|i|output[i]=@as(f64,medians[i]);return @intCast(count);
}
