package breakout
import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"
SCREEN_SIZE :: 320
PADDLE_WIDTH :: 50
PADDLE_HEIGHT :: 10
PADDLE_POS_Y :: 230
PADDLE_SPEED :: 290
BALL_SPEED :: 300
BALL_RADIUS :: 4
BALL_START_Y :: 160
NUM_BLOCKS_X :: 10
NUM_BLOCKS_Y :: 8
BLOCK_WIDTH :: 28
BLOCK_HEIGHT :: 10
Block_Color :: enum {
	Yellow,
	Green,
	Orange,
	Red,
}
row_colors := [NUM_BLOCKS_Y]Block_Color {
	.Red,
	.Red,
	.Orange,
	.Orange,
	.Green,
	.Green,
	.Yellow,
	.Yellow,
}
block_color_values := [Block_Color]rl.Color {
	.Yellow = {251, 243, 193, 255},
	.Green  = {100, 226, 183, 255},
	.Orange = {247, 173, 69, 255},
	.Red    = {247, 155, 114, 255},
}

block_color_score := [Block_Color]int {
	.Yellow = 2,
	.Green  = 4,
	.Orange = 6,
	.Red    = 8,
}


blocks: [NUM_BLOCKS_X][NUM_BLOCKS_Y]bool


paddle_pos_x: f32

ball_pos: rl.Vector2
ball_dir: rl.Vector2
started: bool
gameover: bool
score: int
block_exists :: proc(x, y: int) -> bool {
	if x < 0 || y < 0 || x >= NUM_BLOCKS_X || y >= NUM_BLOCKS_Y {
		return false
	}
	return blocks[x][y]

}
call_block_rect :: proc(x, y: int) -> rl.Rectangle {
	return {f32(20 + x * BLOCK_WIDTH), f32(40 + y * BLOCK_HEIGHT), BLOCK_WIDTH, BLOCK_HEIGHT}
}
restart :: proc() {
	paddle_pos_x = SCREEN_SIZE / 2 - PADDLE_WIDTH / 2
	ball_pos = {SCREEN_SIZE / 2, BALL_START_Y}
	started = false
  for x in 0 ..< NUM_BLOCKS_X {
		for y in 0 ..< NUM_BLOCKS_Y {
			blocks[x][y] = true
		}
	}

}
reflect :: proc(dir, normal: rl.Vector2) -> rl.Vector2 {
	new_direction := linalg.reflect(dir, linalg.normalize(normal))
	return linalg.normalize(new_direction)

}

main :: proc() {


	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(800, 800, "Breakout")

	rl.SetTargetFPS(500)
	restart()
	for !rl.WindowShouldClose() {
		dt: f32

		if !started {
			ball_pos = {
				SCREEN_SIZE / 2 + f32(math.cos(rl.GetTime()) * SCREEN_SIZE / 2.5),
				BALL_START_Y,
			}
			if rl.IsKeyPressed(.SPACE) {
				paddle_middle := rl.Vector2{paddle_pos_x + PADDLE_WIDTH / 2, PADDLE_POS_Y}
				ball_to_paddle := paddle_middle - ball_pos

				ball_dir = linalg.normalize(ball_to_paddle)
				gameover = false
				started = true
			}} else {
			dt = rl.GetFrameTime()
		}
		previous_ball_pos := ball_pos

		ball_pos += ball_dir * BALL_SPEED * dt

		if ball_pos.x + BALL_RADIUS > SCREEN_SIZE {
			ball_dir = reflect(ball_dir, {1, 0})
		}
		if ball_pos.x - BALL_RADIUS < 0 {
			ball_dir = reflect(ball_dir, {-1, 0})
		}
		if ball_pos.y - BALL_RADIUS < 0 {
			ball_dir = reflect(ball_dir, {0, 1})
		}
		if ball_pos.y + BALL_RADIUS > SCREEN_SIZE {
			gameover = true
		}


		paddle_move_velocity: f32
		if rl.IsKeyDown(.LEFT) {
			paddle_move_velocity -= PADDLE_SPEED
		}
		if rl.IsKeyDown(.RIGHT) {
			paddle_move_velocity += PADDLE_SPEED
		}
		paddle_pos_x += paddle_move_velocity * dt
		paddle_pos_x = clamp(paddle_pos_x, 0, SCREEN_SIZE - PADDLE_WIDTH)
		paddle_rect := rl.Rectangle{paddle_pos_x, PADDLE_POS_Y, PADDLE_WIDTH, PADDLE_HEIGHT}

		if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, paddle_rect) {

			collison_normal: rl.Vector2
			if previous_ball_pos.y < paddle_rect.y + paddle_rect.height {
				collison_normal += {0, -1}
				ball_pos.y = paddle_rect.y - BALL_RADIUS

			}
			if previous_ball_pos.y > paddle_rect.y {
				collison_normal += {0, 1}
				ball_pos.y = paddle_rect.y + paddle_rect.height + BALL_RADIUS
			}
			if previous_ball_pos.x < paddle_rect.x {
				collison_normal += {-1, 0}
			}
			if previous_ball_pos.x > paddle_rect.x + paddle_rect.width {
				collison_normal += {1, 0}
			}

			if collison_normal != 0 {
				ball_dir = reflect(ball_dir, collison_normal)
			}


		}
		block_x_loop: for x in 0 ..< NUM_BLOCKS_X {
			for y in 0 ..< NUM_BLOCKS_Y {
				if blocks[x][y] == false {
					continue
				}
				block_rect := call_block_rect(x, y)
				if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, block_rect) {
					collison_normal: rl.Vector2
					if previous_ball_pos.y < block_rect.y {
						collison_normal += {0, -1}
					}
					if previous_ball_pos.y > block_rect.y + block_rect.height {
						collison_normal += {0, 1}}
					if previous_ball_pos.x < block_rect.x {
						collison_normal += {-1, 0}
					}
					if previous_ball_pos.x > block_rect.x + block_rect.width {
						collison_normal += {1, 0}
					}
					if block_exists(x + int(collison_normal.x), y) {
						collison_normal.x = 0

					}
					if block_exists(x, y + int(collison_normal.y)) {
						collison_normal.y = 0
					}
					if collison_normal != 0 {
						ball_dir = reflect(ball_dir, collison_normal)
					}
					blocks[x][y] = false
					row_color := row_colors[y]
					score += block_color_score[row_color]
					break block_x_loop


				}

			}
		}


		rl.BeginDrawing()
		rl.ClearBackground({255, 227, 187, 255})

		camera := rl.Camera2D {
			zoom = f32(rl.GetScreenHeight()) / SCREEN_SIZE,
		}
		rl.BeginMode2D(camera)
		if gameover {
			started = false
			paddle_pos_x = SCREEN_SIZE / 2 - PADDLE_WIDTH / 2
			score = 0
			for x in 0 ..< NUM_BLOCKS_X {
				for y in 0 ..< NUM_BLOCKS_Y {
					blocks[x][y] = true
				}
			}

			// rl.DrawText("Game Over", 4, 20,25,{255, 79, 15,255})
		}

		rl.DrawRectangleRec(paddle_rect, {3, 166, 161, 255})
		rl.DrawCircleV(ball_pos, BALL_RADIUS, {255, 79, 15, 255})
		for x in 0 ..< NUM_BLOCKS_X {
			for y in 0 ..< NUM_BLOCKS_Y {
				if !blocks[x][y] {
					continue
				}
				block_rect := call_block_rect(x, y)

				top_left := rl.Vector2{block_rect.x, block_rect.y}

				top_right := rl.Vector2{block_rect.x + block_rect.width, block_rect.y}

				bottom_left := rl.Vector2{block_rect.x, block_rect.y + block_rect.height}
				bottom_right := rl.Vector2 {
					block_rect.x + block_rect.width,
					block_rect.y + block_rect.height,
				}

				rl.DrawRectangleRec(block_rect, block_color_values[row_colors[y]])
				rl.DrawLineEx(top_left, top_right, 1, {255, 227, 187, 255})
				rl.DrawLineEx(top_left, bottom_left, 1, {255, 227, 187, 255})
				rl.DrawLineEx(bottom_left, bottom_right, 1, {255, 227, 187, 255})
				rl.DrawLineEx(top_right, bottom_right, 1, {255, 227, 187, 255})


			}

		}
		score_text := fmt.ctprintf("Score : %d", score)
		rl.DrawText(score_text, 5, 5, 10, rl.PINK)

		rl.EndMode2D()
		rl.EndDrawing()
		if rl.IsKeyDown(.ESCAPE) {
			rl.WindowShouldClose()
		}
		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}
