// Independent bounded implementation of Stanford Puzzle, attributed by the
// pinned file to Forest Baskett. No upstream code/comments are copied; the
// pinned source has no explicit redistribution grant.
const SIDE: usize = 5;
const CELL_COUNT: usize = 125;
const TYPE_COUNT: usize = 13;
const MAX_SEARCH_CALLS: usize = 2005;
const HOLE_SCALE: i64 = 1_000_000;
const SHAPE_X = [_]usize{4,2,1,2,4,1,3,1,1,2,2,1,2};
const SHAPE_Y = [_]usize{2,1,4,4,1,2,1,3,1,2,1,2,2};
const SHAPE_Z = [_]usize{1,4,2,1,2,4,1,1,3,1,2,2,2};
const SHAPE_CLASS = [_]usize{0,0,0,0,0,0,1,1,1,2,2,2,3};

fn fits(board: *const [CELL_COUNT]bool, start: usize, kind: usize) bool {
    const x0=start%SIDE;const y0=(start/SIDE)%SIDE;const z0=start/(SIDE*SIDE);
    if(x0+SHAPE_X[kind]>SIDE or y0+SHAPE_Y[kind]>SIDE or z0+SHAPE_Z[kind]>SIDE)return false;
    for(0..SHAPE_Z[kind]) |z|{for(0..SHAPE_Y[kind]) |y|{for(0..SHAPE_X[kind]) |x|{if(board.*[(z0+z)*SIDE*SIDE+(y0+y)*SIDE+x0+x])return false;}}}
    return true;
}
fn mark(board: *[CELL_COUNT]bool,start:usize,kind:usize,value:bool) void {
    const x0=start%SIDE;const y0=(start/SIDE)%SIDE;const z0=start/(SIDE*SIDE);
    for(0..SHAPE_Z[kind]) |z|{for(0..SHAPE_Y[kind]) |y|{for(0..SHAPE_X[kind]) |x|{board.*[(z0+z)*SIDE*SIDE+(y0+y)*SIDE+x0+x]=value;}}}
}
fn firstEmpty(board:*const [CELL_COUNT]bool,start:usize)usize{for(start..CELL_COUNT) |i|{if(!board.*[i])return i;}return 0;}
fn sourceIndex(flat:usize)i64{const x=flat%SIDE;const y=(flat/SIDE)%SIDE;const z=flat/(SIDE*SIDE);return @as(i64,@intCast(x+1))+8*@as(i64,@intCast(y+1))+64*@as(i64,@intCast(z+1));}
fn search(board:*[CELL_COUNT]bool,remaining:*[4]usize,start:usize,calls:*usize,overflow:*bool)bool{
    calls.*+=1;if(calls.*>MAX_SEARCH_CALLS){overflow.*=true;return false;}
    for(0..TYPE_COUNT) |kind|{const class_id=SHAPE_CLASS[kind];if(remaining.*[class_id]==0 or !fits(board,start,kind))continue;
        mark(board,start,kind,true);remaining.*[class_id]-=1;const next=firstEmpty(board,start);const child=search(board,remaining,next,calls,overflow);
        if(overflow.*)return false;if(child or next==0)return true;remaining.*[class_id]+=1;mark(board,start,kind,false);
    }
    return false;
}

pub export fn stanford_puzzle(input:?[*]const i64,length:usize)i64{
    const values=input orelse return -1;if(length!=1 or values[0]<1 or values[0]>100)return -1;
    var checksum:i64=0;const passes:usize=@intCast(values[0]);
    for(0..passes) |_|{var board=[_]bool{false} ** CELL_COUNT;var remaining=[_]usize{13,3,1,1};if(!fits(&board,0,0))return -1;
        mark(&board,0,0,true);remaining[0]-=1;const hole=firstEmpty(&board,0);var calls:usize=0;var overflow=false;
        if(hole==0 or !search(&board,&remaining,hole,&calls,&overflow) or overflow)return -1;
        checksum+=sourceIndex(hole)*HOLE_SCALE+@as(i64,@intCast(calls));
    }
    return checksum;
}
