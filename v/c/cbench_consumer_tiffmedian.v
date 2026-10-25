module main

const bin_side = 32
const histogram_size = bin_side * bin_side * bin_side
const max_palette = 8
const max_pixels = 16
const max_input_length = 50

struct ColorBox { rmin int; rmax int; gmin int; gmax int; bmin int; bmax int; total int }

fn hist_at(hist &i32, r int, g int, b int) int {
    return unsafe { hist[(r * bin_side + g) * bin_side + b] }
}

fn shrink_box(hist &i32, mut box ColorBox) {
    mut rmin := bin_side; mut gmin := bin_side; mut bmin := bin_side
    mut rmax := -1; mut gmax := -1; mut bmax := -1
    for r in box.rmin..box.rmax+1 {
        for g in box.gmin..box.gmax+1 {
            for b in box.bmin..box.bmax+1 {
                if hist_at(hist,r,g,b) != 0 {
                    if r < rmin { rmin = r }; if r > rmax { rmax = r }
                    if g < gmin { gmin = g }; if g > gmax { gmax = g }
                    if b < bmin { bmin = b }; if b > bmax { bmax = b }
                }
            }
        }
    }
    box.rmin=rmin;box.rmax=rmax;box.gmin=gmin;box.gmax=gmax;box.bmin=bmin;box.bmax=bmax
}

fn largest_box(boxes [max_palette]ColorBox, count int) int {
    mut selected := -1
    mut largest_total := -1
    for i in 0..count {
        b:=boxes[i]
        if (b.rmax>b.rmin || b.gmax>b.gmin || b.bmax>b.bmin) && b.total>largest_total {
            selected=i;largest_total=b.total
        }
    }
    return selected
}

fn split_box(hist &i32, mut boxes [max_palette]ColorBox, mut count int, selected int) {
    mut upper:=boxes[selected]
    rs:=upper.rmax-upper.rmin;gs:=upper.gmax-upper.gmin;bs:=upper.bmax-upper.bmin
    mut axis:=0
    if !(rs>=gs && rs>=bs) {axis=if gs>=bs {1} else {2}}
    first:=if axis==0 {upper.rmin} else if axis==1 {upper.gmin} else {upper.bmin}
    last:=if axis==0 {upper.rmax} else if axis==1 {upper.gmax} else {upper.bmax}
    mut along:=[bin_side]int{}
    for r in upper.rmin..upper.rmax+1 {for g in upper.gmin..upper.gmax+1 {for b in upper.bmin..upper.bmax+1 {
        coordinate:=if axis==0 {r} else if axis==1 {g} else {b}
        along[coordinate]+=hist_at(hist,r,g,b)
    }}}
    median:=upper.total/2
    mut accumulated:=0;mut split:=first
    for split<=last {accumulated+=along[split];if accumulated>=median{break};split++}
    if split==first {split++}
    mut lower:=upper
    mut lower_total:=0;mut upper_total:=0
    for bin in first..split {lower_total+=along[bin]}
    for bin in split..last+1 {upper_total+=along[bin]}
    lower.total=lower_total;upper.total=upper_total
    if axis==0 {lower.rmax=split-1;upper.rmin=split}
    else if axis==1 {lower.gmax=split-1;upper.gmin=split}
    else {lower.bmax=split-1;upper.bmin=split}
    shrink_box(hist,mut lower);shrink_box(hist,mut upper)
    boxes[selected]=upper
    for i:=count;i>0;i-- {boxes[i]=boxes[i-1]}
    boxes[0]=lower;count++
}

@[export: 'cbench_consumer_tiffmedian']
pub fn cbench_consumer_tiffmedian(input &i64,input_length usize,output &u8,output_capacity usize) i64 {
    if unsafe{input==nil} || input_length<5 || input_length>max_input_length {return -1}
    palette_value:=unsafe{input[0]};pixel_value:=unsafe{input[1]}
    if palette_value<1 || palette_value>max_palette || pixel_value<1 || pixel_value>max_pixels {return -1}
    palette_limit:=int(palette_value);pixel_count:=int(pixel_value)
    if input_length!=usize(2+3*pixel_count) {return -1}
    for i in 0..3*pixel_count {value:=unsafe{input[i+2]};if value<0 || value>255{return -1}}
    mut histogram:=[histogram_size]i32{}
    mut boxes:=[max_palette]ColorBox{}
    mut rmin:=bin_side;mut gmin:=bin_side;mut bmin:=bin_side
    mut rmax:=-1;mut gmax:=-1;mut bmax:=-1
    for p in 0..pixel_count {
        r:=int(unsafe{input[2+3*p]}>>3);g:=int(unsafe{input[3+3*p]}>>3);b:=int(unsafe{input[4+3*p]}>>3)
        histogram[(r*bin_side+g)*bin_side+b]++
        if r<rmin {rmin=r};if r>rmax {rmax=r}
        if g<gmin {gmin=g};if g>gmax {gmax=g}
        if b<bmin {bmin=b};if b>bmax {bmax=b}
    }
    boxes[0]=ColorBox{rmin:rmin,rmax:rmax,gmin:gmin,gmax:gmax,bmin:bmin,bmax:bmax,total:pixel_count}
    mut box_count:=1
    for box_count<palette_limit {
        selected:=largest_box(boxes,box_count)
        if selected<0 {break}
        split_box(&histogram[0],mut boxes,mut box_count,selected)
    }
    output_bytes:=1+3*box_count
    if unsafe{output==nil} || output_capacity<usize(output_bytes) {return -2}
    unsafe {
        output[0]=u8(box_count)
        for i in 0..box_count {
            output[1+3*i]=u8((boxes[i].rmin+boxes[i].rmax)*4)
            output[2+3*i]=u8((boxes[i].gmin+boxes[i].gmax)*4)
            output[3+3*i]=u8((boxes[i].bmin+boxes[i].bmax)*4)
        }
    }
    return i64(output_bytes)
}
