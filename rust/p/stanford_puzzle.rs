// Independent bounded implementation of Stanford Puzzle, attributed by the
// pinned file to Forest Baskett. No upstream source code or comments are
// copied here; the pinned file has no explicit redistribution grant.
const SIDE: usize = 5;
const CELL_COUNT: usize = 125;
const TYPE_COUNT: usize = 13;
const MAX_SEARCH_CALLS: i32 = 2005;
const HOLE_SCALE: i64 = 1_000_000;

#[derive(Clone, Copy)] struct Piece { x: usize, y: usize, z: usize, piece_class: usize }
const PIECES: [Piece; TYPE_COUNT] = [
    Piece{x:4,y:2,z:1,piece_class:0},Piece{x:2,y:1,z:4,piece_class:0},
    Piece{x:1,y:4,z:2,piece_class:0},Piece{x:2,y:4,z:1,piece_class:0},
    Piece{x:4,y:1,z:2,piece_class:0},Piece{x:1,y:2,z:4,piece_class:0},
    Piece{x:3,y:1,z:1,piece_class:1},Piece{x:1,y:3,z:1,piece_class:1},Piece{x:1,y:1,z:3,piece_class:1},
    Piece{x:2,y:2,z:1,piece_class:2},Piece{x:2,y:1,z:2,piece_class:2},Piece{x:1,y:2,z:2,piece_class:2},
    Piece{x:2,y:2,z:2,piece_class:3},
];

fn fits(board: &[bool; CELL_COUNT], start: usize, kind: usize) -> bool {
    let (x0,y0,z0)=(start%SIDE,(start/SIDE)%SIDE,start/(SIDE*SIDE)); let p=PIECES[kind];
    if x0+p.x>SIDE||y0+p.y>SIDE||z0+p.z>SIDE{return false;}
    for z in 0..p.z{for y in 0..p.y{for x in 0..p.x{if board[(z0+z)*SIDE*SIDE+(y0+y)*SIDE+x0+x]{return false;}}}}
    true
}
fn mark(board: &mut [bool; CELL_COUNT],start:usize,kind:usize,value:bool){
    let(x0,y0,z0)=(start%SIDE,(start/SIDE)%SIDE,start/(SIDE*SIDE));let p=PIECES[kind];
    for z in 0..p.z{for y in 0..p.y{for x in 0..p.x{board[(z0+z)*SIDE*SIDE+(y0+y)*SIDE+x0+x]=value;}}}
}
fn first_empty(board:&[bool;CELL_COUNT],from:usize)->usize{for i in from..CELL_COUNT{if !board[i]{return i;}}0}
fn source_index(flat:usize)->i64{let x=flat%SIDE;let y=(flat/SIDE)%SIDE;let z=flat/(SIDE*SIDE);(x+1)as i64+8*(y+1)as i64+64*(z+1)as i64}
fn search(board:&mut[bool;CELL_COUNT],remaining:&mut[i32;4],start:usize,calls:&mut i32,overflow:&mut bool)->bool{
    *calls+=1;if *calls>MAX_SEARCH_CALLS{*overflow=true;return false;}
    for kind in 0..TYPE_COUNT{let class=PIECES[kind].piece_class;if remaining[class]==0||!fits(board,start,kind){continue;}
        mark(board,start,kind,true);remaining[class]-=1;let next=first_empty(board,start);let child=search(board,remaining,next,calls,overflow);
        if *overflow{return false;}if child||next==0{return true;}remaining[class]+=1;mark(board,start,kind,false);
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn stanford_puzzle(input:*const i64,length:usize)->i64{
    if input.is_null()||length!=1{return -1;}let passes=*input;if !(1..=100).contains(&passes){return -1;}
    let mut checksum=0i64;
    for _ in 0..passes{let mut board=[false;CELL_COUNT];let mut remaining=[13,3,1,1];if !fits(&board,0,0){return -1;}
        mark(&mut board,0,0,true);remaining[0]-=1;let hole=first_empty(&board,0);let mut calls=0;let mut overflow=false;
        if hole==0||!search(&mut board,&mut remaining,hole,&mut calls,&mut overflow)||overflow{return -1;}
        checksum+=source_index(hole)*HOLE_SCALE+i64::from(calls);
    }
    checksum
}
