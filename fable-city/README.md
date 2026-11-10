# Fable City

A procedural, low-poly 3D city that lives in a single HTML file. Every load builds a new grid of
streets, towers, offices, shops and homes, then fills it with traffic, pedestrians and a full
day–night cycle.

## Features

- **Procedural city** — seeded generation of blocks, lots and four building types (residential, office, shop, tower), plus parks and trees.
- **Traffic** — cars keep to their lane, follow each other, yield on left turns and obey red / yellow / green signals at every intersection.
- **Pedestrians** — small figures stroll the sidewalks around each block.
- **Day–night cycle** — animated sun and moon, sky and fog gradients, stars, streetlights at dusk, windows that light up (and go dark) through the night, glowing headlights.
- **Inspect buildings** — click any building for its generated name, type, floor count, height and address.
- **Drive a car** — hover to highlight, click any car to take the wheel with a chase camera, arcade physics and building collisions; AI traffic yields to you.
- **HUD** — live clock, time-of-day scrubber, simulation speed slider and a *Regenerate City* button.

## Running it

No build step and no install.

- **Locally:** open `index.html` in a recent Chrome or Firefox. An internet connection is needed the first time, because Three.js is loaded from a CDN through an import map.
- **GitHub Pages:** https://fatihlabsai.github.io/Claude/fable-city/

Append `?seed=<code>` (the seed shown in the HUD) to the URL to rebuild a specific city.

## Controls

| Action | Input |
| --- | --- |
| Orbit | Left-drag (one-finger drag on touch) |
| Pan | Right-drag (two-finger drag) |
| Zoom | Scroll wheel / pinch |
| Inspect a building | Click it (when not driving) |
| Close the info panel | Click empty space, the × button, or press `Esc` |
| Enter a car | Hover a car (highlight) then click it |
| Drive | `W`/`↑` accelerate · `S`/`↓` brake/reverse · `A`/`D` or `←`/`→` steer |
| Exit car | `Esc` or the on-screen *Exit car* button (car returns to AI traffic) |
| Pause / resume | `Space` (also works while driving) |
| New city | `R` or the *Regenerate City* button (disabled while driving) |

## Tech

One file: `index.html`. Rendering uses [Three.js](https://threejs.org/) r170 and `OrbitControls`;
there are no other dependencies or assets. Buildings and windows are merged into a handful of
meshes and everything repeated (cars, people, trees, lights, road markings) is drawn with
`InstancedMesh` to keep draw calls low.

## Credits

Designed and written by **Claude Fable 5.2** (Anthropic).
