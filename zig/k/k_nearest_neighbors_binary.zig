const MAX_DIM:usize=8;
const MAX_POINTS:usize=128;

pub export fn k_nearest_neighbors_binary(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<3)return -1;
    const d64=input[0];const n64=input[1];const k64=input[2];
    if(d64<1 or d64>@as(i64,@intCast(MAX_DIM)) or n64<1 or n64>@as(i64,@intCast(MAX_POINTS)) or k64<1 or k64>n64 or @mod(k64,2)==0 or length!=3+@as(usize,@intCast(d64))+@as(usize,@intCast(n64))*(@as(usize,@intCast(d64))+1))return -1;
    const d:usize=@intCast(d64);const n:usize=@intCast(n64);const k:usize=@intCast(k64);
    for(0..d)|axis|{if(input[3+axis]< -1000 or input[3+axis]>1000)return -1;}
    var distances=[_]i64{0}**MAX_POINTS;var labels=[_]i64{0}**MAX_POINTS;
    for(0..n)|point|{const base=3+d+point*(d+1);var distance:i64=0;
        for(0..d)|axis|{const x=input[base+axis];if(x< -1000 or x>1000)return -1;const delta=x-input[3+axis];distance+=delta*delta;}
        const label=input[base+d];if(label!=0 and label!=1)return -1;
        for(0..point)|prev|{if(distances[prev]==distance)return -1;}
        distances[point]=distance;labels[point]=label;
    }
    for(1..n)|i|{const distance=distances[i];const label=labels[i];var j=i;while(j>0 and distances[j-1]>distance):(j-=1){distances[j]=distances[j-1];labels[j]=labels[j-1];}distances[j]=distance;labels[j]=label;}
    var ones:i64=0;for(0..k)|i|ones+=labels[i];const prediction:i64=if(ones>@as(i64,@intCast(k/2)))1 else 0;
    if(output==null or capacity<8)return -2;
    const bits:u64=@bitCast(prediction);for(0..8)|byte|output[byte]=@truncate(bits>>@intCast(8*byte));return 8;
}
