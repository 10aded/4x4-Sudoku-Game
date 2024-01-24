// TODO: Write summary of 4 x 4 Sudoku game
//
// Created by 10aded Jan 2024 --- ???
//
// This project was compiled using the Zig compiler (version 0.11.0)
// and built with the command:
//
//     zig build -Doptimize=ReleaseFast
//
// run in the top directory of the project.
//
// The entire source code of this project is available on GitHub at:
//
//   https://github.com/10aded/???
//
// and was developed (almost) entirely on the Twitch channel 10aded. Copies of the
// stream are available on YouTube at the @10aded channel.
//
// This project includes a copy of raylib, specifically v5.0 (commit number ae50bfa).
//
// Raylib is created by github user Ray (@github handle raysan5) and available at:
//
//    https://github.com/raysan5a
//
// See the pages above for full license details.

const std = @import("std");
const rl  = @cImport(@cInclude("raylib.h"));

const Vec2   = @Vector(2, f32);

// Constants
// UI Colors
const BLACK     = rlc(  0,   0,   0);
const DARKGRAY  = rlc( 40,  40,  40);
const LIGHTGRAY = rlc(200, 200, 200);
const WHITE     = rlc(255, 255, 255);

const RED       = rlc(255, 0,   0);
const GREEN     = rlc(0,   255, 0);
const BLUE      = rlc(0,   0,   255);
const YELLOW    = rlc(255, 255, 0);
const MAGENTA   = rlc(255, 0,   255);

const DEBUG  = MAGENTA;


const initial_screen_width = 1902;
const initial_screen_hidth = 1080;
const WINDOW_TITLE = "4 x 4 Sudoku Game";

// Globals
// Colors
const grid_fill_color = LIGHTGRAY;
const grid_bar_color  = BLACK;

const background_color = DARKGRAY;


// Screen geometry
var screen_width : f32 = undefined;
var screen_hidth : f32 = undefined;



// Grid Tile Possiblities
// Note: 0 denotes an empty tile
// Positive number represents a fixed tile
// Negative number represents a selected tile.

const Tile = i8;

const Grid = [16] Tile;

const grid1 = Grid{1,2,3,4,
                   4,3,2,1,
                   2,1,4,3,
                   3,4,1,2};

// TODO:
// Write procedure to validate whether or not a given grid is a valid solution.

pub fn main() anyerror!void {

    // Set up RNG.
    // const seed  = std.time.milliTimestamp();
    // prng        = std.rand.DefaultPrng.init(@intCast(seed));

    // Spawn / setup raylib window.    
    rl.InitWindow(initial_screen_width, initial_screen_hidth, WINDOW_TITLE);
    defer rl.CloseWindow();

    rl.SetWindowState(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetTargetFPS(144);

    // Import font from embedded file.
//    const merriweather_font = rl.LoadFontFromMemory(".ttf", merriweather_ttf, merriweather_ttf.len, 108, null, 95);

    // button_option_font = merriweather_font;
    // attribution_font   = merriweather_font;
    
//    const random = prng.random();

    // +----------------+
    // | Main game loop |
    // +----------------+
    while ( ! rl.WindowShouldClose() ) { // Listen for close button or ESC key.

        screen_width = @floatFromInt(rl.GetScreenWidth());
        screen_hidth = @floatFromInt(rl.GetScreenHeight());
        
//        process_input_update_state();

        render();
    }
}


fn render() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.ClearBackground(background_color);

    render_grid(grid1);

}

fn render_grid(grid : Grid) void {
    const pos = Vec2{0.5 * screen_width, 0.5 * screen_hidth};
    // Set sizes of grid elements.
    const minimum_screen_dim = @min(screen_width, screen_hidth);
    const square_length = 0.1  * minimum_screen_dim;
    const bar_thickness = 0.01 * minimum_screen_dim;
    const total_length = 5 * bar_thickness + 4 * square_length;


    // Draw grid background.
    const background_length = total_length - bar_thickness;
    draw_centered_rect(pos, background_length, background_length, grid_fill_color);
    


    // Draw the (non-empty) tiles in the grid.
    // @temp (!!!)
    // 1 |-> red
    // 2 |-> green
    // 3 |-> blue
    // 4 |-> yellow

    const tl_square_pos = pos - Vec2{1.5 * ( square_length + bar_thickness), 1.5 * ( square_length + bar_thickness)};
    
    for (grid, 0..) |tile, i| {
        const xi = @as(f32, @floatFromInt(i % 4));
        const yi = @as(f32, @floatFromInt(i / 4));
        const color = switch(tile) {
            1 => RED,
            2 => GREEN,
            3 => BLUE,
            4 => YELLOW,
            else => DEBUG,
        };
        const rect_pos = tl_square_pos + Vec2{xi * (square_length + bar_thickness), yi * (square_length + bar_thickness)};
        const tile_len = square_length + 0.5 * bar_thickness;
        draw_centered_rect(rect_pos, tile_len, tile_len, color);
    }

        // Draw vertical grid bars.
    for (0..5) |i| {
        const offset = @as(f32, @floatFromInt(i)) - 2;
        draw_centered_rect(pos + Vec2{offset * (square_length + bar_thickness), 0}, bar_thickness, total_length, grid_bar_color);
        draw_centered_rect(pos + Vec2{0, offset * (square_length + bar_thickness)}, total_length, bar_thickness, grid_bar_color);
    }
}


// Draw a plain (colored) rectangle, where the position determines the center.

fn draw_centered_rect( pos : Vec2, width : f32, height : f32, color : rl.Color) void {
    const top_left_x : i32 = @intFromFloat(pos[0] - 0.5 * width);
    const top_left_y : i32 = @intFromFloat(pos[1] - 0.5 * height);
    rl.DrawRectangle(top_left_x, top_left_y, @intFromFloat(width), @intFromFloat(height), color);
}

fn rlc(r : u8, g : u8, b : u8) rl.Color {
    const rlcolor = rl.Color{
        .r = r,
        .g = g,
        .b = b,
        .a = 255,
    };
    return rlcolor;
}
