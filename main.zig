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
const WHITE     = rlc(255, 255, 255);

const background_color = BLACK;

const initial_screen_width = 1902;
const initial_screen_hidth = 1080;
const WINDOW_TITLE = "4 x 4 Sudoku Game";

// Globals

var screen_width : f32 = undefined;
var screen_hidth : f32 = undefined;


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

    draw_centered_rect(Vec2{0.5 * screen_width, 0.5 * screen_hidth}, 200, 200, WHITE);

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
