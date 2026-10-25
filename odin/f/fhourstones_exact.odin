/*
Fhourstones 2.0 copyright and distribution notice:
This software is copyright (c) 1996 by John Tromp, Lindenlaan 33,
1701 GT Heerhugowaard, Netherlands. E-mail: tromp@cwi.nl.
This notice must not be removed. This software must not be sold for profit.
You may redistribute if your distributees have the same rights and restrictions.

Fhourstones 3.1 copyright and distribution notice:
This software is copyright (c) 1996-2005 by John Tromp, Insulindeweg 908,
1095 DX Amsterdam, Netherlands. E-mail: tromp@cwi.nl.
This notice must not be removed. This software must not be sold for profit.
You may redistribute if your distributees have the same rights and restrictions.
*/
package fhourstones_exact

import "core:c"

WIDTH :: 7
HEIGHT :: 6
BOARD_CELLS :: 42
MIN_MOVES :: 36
MAX_MOVES :: 41
MOVE_ORDER :: [7]int{3, 2, 4, 1, 5, 0, 6}
DIR_X :: [4]int{1, 0, 1, 1}
DIR_Y :: [4]int{0, 1, 1, -1}

wins_at :: proc "contextless" (board: [^]i8, column, row, side: int) -> bool {
	for direction := 0; direction < 4; direction += 1 {
		count := 1
		for sign_index := 0; sign_index < 2; sign_index += 1 {
			sign := -1
			if sign_index == 1 { sign = 1 }
			for step := 1; step < 4; step += 1 {
				x := column + sign*step*DIR_X[direction]
				y := row + sign*step*DIR_Y[direction]
				if x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT { break }
				if board[y*WIDTH+x] != i8(side) { break }
				count += 1
			}
		}
		if count >= 4 { return true }
	}
	return false
}

solve_endgame :: proc "contextless" (board: [^]i8, heights: [^]int, side, remaining, alpha_in, beta: int) -> int {
	if remaining == 0 { return 0 }
	alpha := alpha_in
	best := -3
	for index := 0; index < WIDTH; index += 1 {
		column := MOVE_ORDER[index]
		row := heights[column]
		if row == HEIGHT { continue }
		board[row*WIDTH+column] = i8(side)
		heights[column] = row + 1
		value := 2
		if !wins_at(board, column, row, side) {
			next_side := 1
			if side == 1 { next_side = 2 }
			value = -solve_endgame(board, heights, next_side, remaining-1, -beta, -alpha)
		}
		heights[column] = row
		board[row*WIDTH+column] = 0
		if value > best { best = value }
		if value > alpha { alpha = value }
		if alpha >= beta { break }
	}
	return best
}

@(export)
fhourstones_exact :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 42 { return -1 }
	count_value := input[0]
	if count_value < MIN_MOVES || count_value > MAX_MOVES { return -1 }
	count := int(count_value)
	if length != c.size_t(count+1) { return -1 }
	board: [BOARD_CELLS]i8 = {}
	heights: [WIDTH]int = {}
	for turn := 0; turn < count; turn += 1 {
		column_value := input[turn+1]
		if column_value < 0 || column_value >= WIDTH { return -1 }
		column := int(column_value)
		row := heights[column]
		if row >= HEIGHT { return -1 }
		side := 1
		if turn%2 == 1 { side = 2 }
		board[row*WIDTH+column] = i8(side)
		heights[column] = row + 1
		if wins_at(&board[0], column, row, side) { return -1 }
	}
	side := 1
	if count%2 == 1 { side = 2 }
	return i64(solve_endgame(&board[0], &heights[0], side, BOARD_CELLS-count, -3, 3))
}
