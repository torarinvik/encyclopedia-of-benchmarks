module table_compression_optimal_contiguous_partition
const max_rows=8
const max_cols=8
const max_input=66
const output_bytes=24
fn interval_cost(input &i64,rows int,cols int,begin int,end int)int{mut runs:=0;mut have:=false;mut previous:=i64(0);for row in 0..rows{for col in begin..end{value:=input[2+row*cols+col];if !have||value!=previous{runs++};previous=value;have=true}};return 2*runs}
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for byte in 0..8{unsafe{output[offset+byte]=u8((bits>>(8*byte))&255)}}}
@[export:'table_compression_optimal_contiguous_partition']
pub fn table_compression_optimal_contiguous_partition(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{
 if input==nil||length<3||length>max_input{return -1};rows64,cols64:=input[0],input[1];if rows64<1||rows64>max_rows||cols64<1||cols64>max_cols{return -1};rows,cols:=int(rows64),int(cols64);if length!=usize(2+rows*cols){return -1};for i in 0..rows*cols{if input[2+i]<0||input[2+i]>15{return -1}}
 mut cost:=[max_cols+1]int{};mut previous:=[max_cols+1]int{};for end in 1..cols+1{cost[end]=0x3fffffff;for start in 0..end{candidate:=cost[start]+interval_cost(input,rows,cols,start,end);if candidate<cost[end]{cost[end]=candidate;previous[end]=start}}}
 mut groups:=0;mut cuts:=u64(0);mut end:=cols;for end>0{start:=previous[end];if start>0{cuts|=u64(1)<<(start-1)};groups++;end=start};mut staged:=[output_bytes]u8{};put_i64(mut &staged[0],0,i64(cost[cols]));put_i64(mut &staged[0],8,i64(groups));put_i64(mut &staged[0],16,i64(cuts));if output==nil||capacity<output_bytes{return -2};for i in 0..output_bytes{output[i]=staged[i]};return i64(output_bytes)
}}
