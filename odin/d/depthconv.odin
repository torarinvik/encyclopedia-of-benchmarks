package depthconv
import "core:c"
MAX_CHANNELS :: 8
rounded_shift :: proc(x:i64, shift:i32)->i64{d:=i64(1)<<shift;if x>=0{return x/d};return -((-x+d-1)/d)}
@(export)
depthconv :: proc "c" (values:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if values==nil||length<1||length>c.size_t(1+11*MAX_CHANNELS) do return -1;channels:=values[0];if channels<1||channels>MAX_CHANNELS||length!=c.size_t(1+11*channels) do return -1;c0:=int(channels);for i:=1;i<1+8*c0;i+=1{if values[i] < -128||values[i]>127 do return -1};for i:=1+8*c0;i<1+9*c0;i+=1{if values[i] < -1_000_000||values[i]>1_000_000 do return -1};for i:=1+9*c0;i<1+10*c0;i+=1{if values[i]<0||values[i]>2_147_483_647 do return -1};for i:=1+10*c0;i<c0*11+1;i+=1{if values[i] < -8||values[i]>0 do return -1};if output==nil||capacity<c.size_t(c0) do return -2;for ch:=0;ch<c0;ch+=1{acc:i32=0;for row:=0;row<4;row+=1{acc+=i32(values[1+row*c0+ch]+128)*i32(values[1+4*c0+row*c0+ch])};acc+=i32(values[1+8*c0+ch]);shift:=i32(31-values[1+10*c0+ch]);round:=i64(1)<<(shift-1);scaled:=rounded_shift(i64(acc)*values[1+9*c0+ch]+round,shift);if scaled>127{scaled=127};if scaled< -128{scaled=-128};output[ch]=u8(i8(scaled))};return channels}
