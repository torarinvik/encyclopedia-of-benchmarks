fn popcount(value_in: u32) u32 { var value=value_in; var count:u32=0; while(value!=0){count+=value&1;value>>=1;} return count; }
fn putI64Le(out:[*]u8,offset:usize,value:i64) void { const bits:u64=@bitCast(value); for(0..8)|b|out[offset+b]=@truncate(bits>>@intCast(8*b)); }

pub export fn association(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<2)return -1;
    const n64=input[0]; const items64=input[1]; if(n64<1 or n64>64 or items64<1 or items64>11)return -1;
    const transactions:usize=@intCast(n64); const items:u32=@intCast(items64); if(length!=2+transactions)return -1;
    const limit:u32=@as(u32,1)<<@intCast(items); const valid_bits:i64=@intCast(limit-1);
    for(0..transactions)|t|{const row=input[2+t];if(row<0 or row>valid_bits)return -1;}
    var frequent=[_]bool{false}**2048; var masks=[_]i64{0}**2047; var supports=[_]i64{0}**2047; var count:usize=0;
    for(1..items+1)|size|{for(1..limit)|mask|{
        if(popcount(mask)!=size)continue;
        if(size>1){var ok=true;for(0..items)|bit|{const bit_mask:u32=@as(u32,1)<<@intCast(bit);if(mask&bit_mask!=0 and !frequent[mask^bit_mask])ok=false;}if(!ok)continue;}
        var support:i64=0;for(0..transactions)|t|{if((@as(u32,@intCast(input[2+t]))&mask)==mask)support+=1;}
        if(support>0){frequent[mask]=true;masks[count]=@intCast(mask);supports[count]=support;count+=1;}
    }}
    const required=count*16;if(capacity<required or(required>0 and output==null))return -2;if(required==0)return 0;
    for(0..count)|i|{putI64Le(output,i*16,masks[i]);putI64Le(output,i*16+8,supports[i]);}
    return @intCast(required);
}
