package cbench_consumer_tiffmedian

import "core:c"

BIN_SIDE :: 32
HISTOGRAM_SIZE :: BIN_SIDE * BIN_SIDE * BIN_SIDE
MAX_PALETTE :: 8
MAX_PIXELS :: 16
MAX_INPUT_LENGTH :: 50

Color_Box :: struct { rmin, rmax, gmin, gmax, bmin, bmax, total: int }

hist_at :: proc(hist: [^]i32, r, g, b: int) -> int {
    return int(hist[(r * BIN_SIDE + g) * BIN_SIDE + b])
}

shrink_box :: proc(hist: [^]i32, box: ^Color_Box) {
    rmin, gmin, bmin := BIN_SIDE, BIN_SIDE, BIN_SIDE
    rmax, gmax, bmax := -1, -1, -1
    for r := box.rmin; r <= box.rmax; r += 1 {
        for g := box.gmin; g <= box.gmax; g += 1 {
            for b := box.bmin; b <= box.bmax; b += 1 {
                if hist_at(hist,r,g,b) != 0 {
                    if r < rmin do rmin = r
                    if r > rmax do rmax = r
                    if g < gmin do gmin = g
                    if g > gmax do gmax = g
                    if b < bmin do bmin = b
                    if b > bmax do bmax = b
                }
            }
        }
    }
    box.rmin=rmin; box.rmax=rmax; box.gmin=gmin; box.gmax=gmax; box.bmin=bmin; box.bmax=bmax
}

largest_box :: proc(boxes: [^]Color_Box, count: int) -> int {
    selected, largest_total := -1, -1
    for i := 0; i < count; i += 1 {
        box := boxes[i]
        if (box.rmax>box.rmin || box.gmax>box.gmin || box.bmax>box.bmin) && box.total>largest_total {
            selected=i;largest_total=box.total
        }
    }
    return selected
}

split_box :: proc(hist: [^]i32, boxes: [^]Color_Box, count: ^int, selected: int) {
    upper := boxes[selected]
    rs,gs,bs := upper.rmax-upper.rmin,upper.gmax-upper.gmin,upper.bmax-upper.bmin
    axis := 0
    if !(rs>=gs && rs>=bs) { axis = 1; if gs<bs do axis=2 }
    first := upper.rmin
    last := upper.rmax
    if axis==1 { first=upper.gmin;last=upper.gmax }
    if axis==2 { first=upper.bmin;last=upper.bmax }
    along: [BIN_SIDE]int = {}
    for r := upper.rmin; r <= upper.rmax; r += 1 {
        for g := upper.gmin; g <= upper.gmax; g += 1 {
            for b := upper.bmin; b <= upper.bmax; b += 1 {
                coordinate := r
                if axis==1 {coordinate=g};if axis==2 {coordinate=b}
                along[coordinate] += hist_at(hist,r,g,b)
            }
        }
    }
    median:=upper.total/2
    accumulated,split:=0,first
    for split<=last {
        accumulated+=along[split]
        if accumulated>=median do break
        split+=1
    }
    if split==first do split+=1
    lower:=upper
    lower_total,upper_total:=0,0
    for bin:=first;bin<split;bin+=1 {lower_total+=along[bin]}
    for bin:=split;bin<=last;bin+=1 {upper_total+=along[bin]}
    lower.total=lower_total;upper.total=upper_total
    if axis==0 {lower.rmax=split-1;upper.rmin=split}
    if axis==1 {lower.gmax=split-1;upper.gmin=split}
    if axis==2 {lower.bmax=split-1;upper.bmin=split}
    shrink_box(hist,&lower);shrink_box(hist,&upper)
    boxes[selected]=upper
    for i:=count^;i>0;i-=1 {boxes[i]=boxes[i-1]}
    boxes[0]=lower
    count^+=1
}

@(export)
cbench_consumer_tiffmedian :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input==nil || input_length<5 || input_length>MAX_INPUT_LENGTH do return -1
    palette_value,pixel_value:=input[0],input[1]
    if palette_value<1 || palette_value>MAX_PALETTE || pixel_value<1 || pixel_value>MAX_PIXELS do return -1
    palette_limit,pixel_count:=int(palette_value),int(pixel_value)
    if input_length!=c.size_t(2+3*pixel_count) do return -1
    for i:=0;i<3*pixel_count;i+=1 {if input[i+2]<0 || input[i+2]>255 do return -1}
    histogram: [HISTOGRAM_SIZE]i32 = {}
    boxes: [MAX_PALETTE]Color_Box = {}
    rmin,gmin,bmin:=BIN_SIDE,BIN_SIDE,BIN_SIDE
    rmax,gmax,bmax:=-1,-1,-1
    for p:=0;p<pixel_count;p+=1 {
        r,g,b:=int(input[2+3*p]>>3),int(input[3+3*p]>>3),int(input[4+3*p]>>3)
        histogram[(r*BIN_SIDE+g)*BIN_SIDE+b]+=1
        if r<rmin do rmin=r;if r>rmax do rmax=r
        if g<gmin do gmin=g;if g>gmax do gmax=g
        if b<bmin do bmin=b;if b>bmax do bmax=b
    }
    boxes[0]=Color_Box{rmin,rmax,gmin,gmax,bmin,bmax,pixel_count}
    box_count:=1
    for box_count<palette_limit {
        selected:=largest_box(&boxes[0],box_count)
        if selected<0 do break
        split_box(&histogram[0],&boxes[0],&box_count,selected)
    }
    output_bytes:=1+3*box_count
    if output==nil || output_capacity<c.size_t(output_bytes) do return -2
    output[0]=u8(box_count)
    for i:=0;i<box_count;i+=1 {
        output[1+3*i]=u8((boxes[i].rmin+boxes[i].rmax)*4)
        output[2+3*i]=u8((boxes[i].gmin+boxes[i].gmax)*4)
        output[3+3*i]=u8((boxes[i].bmin+boxes[i].bmax)*4)
    }
    return i64(output_bytes)
}
