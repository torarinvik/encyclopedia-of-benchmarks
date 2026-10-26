package table_compression_optimal_contiguous_partition
import "core:c"

MAX_ROWS :: 8
MAX_COLS :: 8
MAX_INPUT :: 66
OUTPUT_BYTES :: 24

interval_cost :: proc(input:[^]i64,rows,cols,begin_col,end_col:int)->i64 {
    runs:=i64(0); have_previous:=false; previous:=i64(0)
    for row:=0;row<rows;row+=1 {
        for col:=begin_col;col<end_col;col+=1 {
            value:=input[2+row*cols+col]
            if !have_previous||value!=previous { runs+=1 }
            previous=value;have_previous=true
        }
    }
    return 2*runs
}

put_i64 :: proc(output:[^]u8,offset:int,value:i64) {
    bits:=u64(value)
    for byte:=0;byte<8;byte+=1 { output[offset+byte]=u8(bits&255);bits>>=8 }
}

@(export)
table_compression_optimal_contiguous_partition :: proc "c" (
    input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<3||length>MAX_INPUT { return -1 }
    rows64,cols64:=input[0],input[1]
    if rows64<1||rows64>MAX_ROWS||cols64<1||cols64>MAX_COLS { return -1 }
    rows,cols:=int(rows64),int(cols64)
    if length!=c.size_t(2+rows*cols) { return -1 }
    for i:=0;i<rows*cols;i+=1 { if input[2+i]<0||input[2+i]>15 { return -1 } }

    costs:[MAX_COLS+1]i64
    previous:[MAX_COLS+1]int
    for finish:=1;finish<=cols;finish+=1 {
        costs[finish]=0x3fffffff
        for start:=0;start<finish;start+=1 {
            candidate:=costs[start]+interval_cost(input,rows,cols,start,finish)
            if candidate<costs[finish] { costs[finish]=candidate;previous[finish]=start }
        }
    }
    groups:=i64(0);cuts:=u64(0);finish:=cols
    for finish>0 {
        start:=previous[finish]
        if start>0 { cuts|=u64(1)<<u32(start-1) }
        groups+=1;finish=start
    }
    staged:[OUTPUT_BYTES]u8
    put_i64(&staged[0],0,costs[cols]);put_i64(&staged[0],8,groups);put_i64(&staged[0],16,i64(cuts))
    if output==nil||capacity<c.size_t(OUTPUT_BYTES) { return -2 }
    for i:=0;i<OUTPUT_BYTES;i+=1 { output[i]=staged[i] }
    return OUTPUT_BYTES
}
