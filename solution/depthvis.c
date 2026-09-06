#include <math.h>
#include <stdlib.h>
#include <SDL2/SDL.h>
#include "libtci.h"

# define WINDOW_W       640
# define WINDOW_H       480
# define SPRITE_COUNT   6
# define SPRITE_SIZE    80

typedef struct s_sprite
{
    int         x;
    int         depth;
    float       phase;
    SDL_Color   color;
}   t_sprite;

static int cmp_sprites_by_depth(void const *a, void const *b)
{
    t_sprite const  *sa;
    t_sprite const  *sb;

    sa = a;
    sb = b;
    return (sa->depth - sb->depth);
}

static void init_sprites(t_sprite *sprites)
{
    SDL_Color const colours[SPRITE_COUNT] = {
        {220, 60, 60, 255}, {60, 200, 90, 255}, {70, 120, 220, 255},
        {230, 200, 60, 255}, {200, 90, 210, 255}, {60, 200, 200, 255}
    };
    int i;

    i = 0;
    while (i < SPRITE_COUNT) {
        sprites[i].x = 40 + i * 50;
        sprites[i].depth = WINDOW_H / 2;
        sprites[i].phase = (float)i * 1.1f;
        sprites[i].color = colours[i];
        i++;
    }
}

static void update_sprites(t_sprite *sprites, Uint32 ticks)
{
    int     i;
    float   t;
    float   wave;

    t = (float)ticks / 1000.0f;
    i = 0;
    while (i < SPRITE_COUNT) {
        wave = sinf(t * 1.3f + sprites[i].phase);
        sprites[i].depth = (int)((float)(WINDOW_H / 2) + wave * 150.0f);
        i++;
    }
}

static void render_sprites(SDL_Renderer *ren, t_sprite *sprites,
        int sort_enabled)
{
    SDL_Rect    rect;
    int         i;

    if (sort_enabled)
        qsort(sprites, SPRITE_COUNT, sizeof(t_sprite),
            cmp_sprites_by_depth);
    SDL_SetRenderDrawColor(ren, 20, 20, 30, 255);
    SDL_RenderClear(ren);
    i = 0;
    while (i < SPRITE_COUNT) {
        rect.x = sprites[i].x;
        rect.y = sprites[i].depth;
        rect.w = SPRITE_SIZE;
        rect.h = SPRITE_SIZE;
        SDL_SetRenderDrawColor(ren, sprites[i].color.r,
            sprites[i].color.g, sprites[i].color.b, 255);
        SDL_RenderFillRect(ren, &rect);
        i++;
    }
    SDL_RenderPresent(ren);
}

int main(void)
{
    SDL_Window      *win;
    SDL_Renderer    *ren;
    SDL_Event       ev;
    t_sprite        sprites[SPRITE_COUNT];
    int             running;
    int             sort_enabled;

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        SDL_Log("SDL_Init: %s", SDL_GetError());
        return (1);
    }
    win = SDL_CreateWindow("depthvis", SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED, WINDOW_W, WINDOW_H, 0);
    ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
    init_sprites(sprites);
    running = 1;
    sort_enabled = 1;
    while (running) {
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT)
                running = 0;
            if (ev.type == SDL_KEYDOWN) {
                if (ev.key.keysym.sym == SDLK_ESCAPE)
                    running = 0;
                if (ev.key.keysym.sym == SDLK_SPACE && !ev.key.repeat)
                    sort_enabled = !sort_enabled;
            }
        }
        update_sprites(sprites, SDL_GetTicks());
        render_sprites(ren, sprites, sort_enabled);
        SDL_Delay(16);
    }
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return (0);
}
