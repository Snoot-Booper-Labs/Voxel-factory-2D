/**
 * Generate placeholder sprite sheet PNGs for the graphics pipeline.
 * Uses Node.js built-in zlib for DEFLATE — no dependencies required.
 *
 * All sprites are colored rectangles with simple patterns so they're
 * visually distinct in-game while remaining placeholder quality.
 */
import { writeFileSync, mkdirSync } from 'fs';
import { deflateSync } from 'zlib';
import { join } from 'path';

const GAME_DIR = join(import.meta.dirname, '..', 'game');

// ============================================================================
// Minimal PNG encoder (RGBA, no filtering)
// ============================================================================

function crc32(buf) {
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    crc ^= buf[i];
    for (let j = 0; j < 8; j++) {
      crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function makeChunk(type, data) {
  const typeBytes = Buffer.from(type, 'ascii');
  const combined = Buffer.concat([typeBytes, data]);
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(combined), 0);
  return Buffer.concat([len, combined, crc]);
}

function createPNG(width, height, pixels) {
  // pixels: Uint8Array of RGBA values (width * height * 4)
  // Add filter byte (0 = None) before each row
  const rawData = Buffer.alloc(height * (1 + width * 4));
  for (let y = 0; y < height; y++) {
    rawData[y * (1 + width * 4)] = 0; // filter: None
    pixels.copy(rawData, y * (1 + width * 4) + 1, y * width * 4, (y + 1) * width * 4);
  }

  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 6;  // color type: RGBA
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace

  const compressed = deflateSync(rawData);

  return Buffer.concat([
    signature,
    makeChunk('IHDR', ihdr),
    makeChunk('IDAT', compressed),
    makeChunk('IEND', Buffer.alloc(0)),
  ]);
}

// ============================================================================
// Color helpers
// ============================================================================

function rgba(r, g, b, a = 255) {
  return [r, g, b, a];
}

function setPixel(pixels, width, x, y, color) {
  const idx = (y * width + x) * 4;
  pixels[idx] = color[0];
  pixels[idx + 1] = color[1];
  pixels[idx + 2] = color[2];
  pixels[idx + 3] = color[3];
}

function fillRect(pixels, width, x0, y0, w, h, color) {
  for (let y = y0; y < y0 + h; y++) {
    for (let x = x0; x < x0 + w; x++) {
      setPixel(pixels, width, x, y, color);
    }
  }
}

function fillFrame(pixels, totalWidth, frameIdx, frameW, frameH, color) {
  fillRect(pixels, totalWidth, frameIdx * frameW, 0, frameW, frameH, color);
}

// Add a small detail pattern (cross or dot) to make frames distinguishable
function addCross(pixels, totalWidth, cx, cy, color) {
  setPixel(pixels, totalWidth, cx, cy, color);
  if (cx > 0) setPixel(pixels, totalWidth, cx - 1, cy, color);
  if (cx < totalWidth - 1) setPixel(pixels, totalWidth, cx + 1, cy, color);
  if (cy > 0) setPixel(pixels, totalWidth, cx, cy - 1, color);
  setPixel(pixels, totalWidth, cx, cy + 1, color);
}

// ============================================================================
// Generators
// ============================================================================

/**
 * Terrain atlas: 15 tiles × 16px = 240×16 horizontal strip.
 * BlockType enum values 0-14 map to atlas X coordinates.
 * AIR (0) is transparent, rest get distinct colors with noise.
 */
function generateTerrainAtlas() {
  const tileCount = 15;
  const tileSize = 16;
  const width = tileCount * tileSize;
  const height = tileSize;
  const pixels = Buffer.alloc(width * height * 4);

  // Colors for each BlockType (index = enum value)
  const tileColors = [
    rgba(0, 0, 0, 0),           // 0: AIR (transparent)
    rgba(76, 153, 51),          // 1: GRASS
    rgba(140, 90, 46),          // 2: DIRT
    rgba(128, 128, 128),        // 3: STONE
    rgba(140, 90, 13),          // 4: WOOD
    rgba(51, 140, 38),          // 5: LEAVES
    rgba(217, 204, 140),        // 6: SAND
    rgba(51, 102, 204, 180),    // 7: WATER (semi-transparent)
    rgba(64, 64, 64),           // 8: COAL_ORE
    rgba(179, 140, 115),        // 9: IRON_ORE
    rgba(217, 191, 51),         // 10: GOLD_ORE
    rgba(102, 217, 230),        // 11: DIAMOND_ORE
    rgba(115, 115, 115),        // 12: COBBLESTONE
    rgba(179, 128, 64),         // 13: PLANKS
    rgba(51, 51, 51),           // 14: BEDROCK
  ];

  for (let t = 0; t < tileCount; t++) {
    const baseColor = tileColors[t];
    for (let y = 0; y < tileSize; y++) {
      for (let x = 0; x < tileSize; x++) {
        // Add slight noise for texture
        const noise = ((x * 7 + y * 13 + t * 3) % 5) * 4 - 8;
        const color = rgba(
          Math.max(0, Math.min(255, baseColor[0] + noise)),
          Math.max(0, Math.min(255, baseColor[1] + noise)),
          Math.max(0, Math.min(255, baseColor[2] + noise)),
          baseColor[3]
        );
        setPixel(pixels, width, t * tileSize + x, y, color);
      }
    }

    // Add ore speckles for ore types (8-11)
    if (t >= 8 && t <= 11) {
      const speckleColor = t === 8 ? rgba(20, 20, 20) :
                           t === 9 ? rgba(200, 160, 130) :
                           t === 10 ? rgba(255, 230, 50) :
                                     rgba(140, 255, 255);
      const ox = t * tileSize;
      setPixel(pixels, width, ox + 4, 4, speckleColor);
      setPixel(pixels, width, ox + 10, 6, speckleColor);
      setPixel(pixels, width, ox + 7, 11, speckleColor);
      setPixel(pixels, width, ox + 12, 3, speckleColor);
      setPixel(pixels, width, ox + 3, 9, speckleColor);
    }

    // Add plank lines for PLANKS (13)
    if (t === 13) {
      const ox = t * tileSize;
      for (let x = 0; x < tileSize; x++) {
        setPixel(pixels, width, ox + x, 4, rgba(140, 100, 40));
        setPixel(pixels, width, ox + x, 11, rgba(140, 100, 40));
      }
    }

    // Add grass tuft on top for GRASS (1)
    if (t === 1) {
      const ox = t * tileSize;
      for (let x = 0; x < tileSize; x++) {
        setPixel(pixels, width, ox + x, 0, rgba(40, 180, 30));
        setPixel(pixels, width, ox + x, 1, rgba(50, 170, 35));
        setPixel(pixels, width, ox + x, 2, rgba(60, 160, 40));
      }
    }
  }

  return createPNG(width, height, pixels);
}

/**
 * Item icon atlas: 8 columns × 4 rows = 32 cells, 16×16 each → 128×64
 * Maps ItemType enum values to grid positions via SpriteDB.
 * We generate 26 icons for all current ItemTypes.
 */
function generateItemIconAtlas() {
  const cols = 8;
  const rows = 4;
  const cellSize = 16;
  const width = cols * cellSize;
  const height = rows * cellSize;
  const pixels = Buffer.alloc(width * height * 4);

  // ItemType → atlas position, plus color and a simple shape hint
  const items = [
    // Row 0: Block items (NONE=skip, DIRT, STONE, WOOD, LEAVES, SAND, GRASS, COBBLESTONE)
    { col: 0, row: 0, color: rgba(0, 0, 0, 0) },                     // NONE (transparent)
    { col: 1, row: 0, color: rgba(140, 90, 46), label: 'block' },     // DIRT
    { col: 2, row: 0, color: rgba(128, 128, 128), label: 'block' },   // STONE
    { col: 3, row: 0, color: rgba(140, 90, 13), label: 'block' },     // WOOD
    { col: 4, row: 0, color: rgba(51, 140, 38), label: 'block' },     // LEAVES
    { col: 5, row: 0, color: rgba(217, 204, 140), label: 'block' },   // SAND
    { col: 6, row: 0, color: rgba(76, 153, 51), label: 'block' },     // GRASS
    { col: 7, row: 0, color: rgba(115, 115, 115), label: 'block' },   // COBBLESTONE
    // Row 1: PLANKS, BEDROCK, MINER, CONVEYOR, (unused x4)
    { col: 0, row: 1, color: rgba(179, 128, 64), label: 'block' },    // PLANKS
    { col: 1, row: 1, color: rgba(51, 51, 51), label: 'block' },      // BEDROCK
    { col: 2, row: 1, color: rgba(51, 51, 51), label: 'gear' },       // MINER
    { col: 3, row: 1, color: rgba(89, 89, 102), label: 'arrow' },     // CONVEYOR
    // Row 2: Materials — COAL, IRON_ORE, GOLD_ORE, IRON_INGOT, GOLD_INGOT, DIAMOND (+ 2 unused)
    { col: 0, row: 2, color: rgba(38, 38, 38), label: 'gem' },        // COAL
    { col: 1, row: 2, color: rgba(179, 140, 115), label: 'gem' },     // IRON_ORE
    { col: 2, row: 2, color: rgba(217, 191, 51), label: 'gem' },      // GOLD_ORE
    { col: 3, row: 2, color: rgba(191, 191, 191), label: 'ingot' },   // IRON_INGOT
    { col: 4, row: 2, color: rgba(242, 217, 38), label: 'ingot' },    // GOLD_INGOT
    { col: 5, row: 2, color: rgba(102, 217, 230), label: 'gem' },     // DIAMOND
    // Row 3: Tools — WOODEN_PICKAXE through IRON_SHOVEL
    { col: 0, row: 3, color: rgba(140, 90, 13), label: 'pick' },      // WOODEN_PICKAXE
    { col: 1, row: 3, color: rgba(128, 128, 128), label: 'pick' },    // STONE_PICKAXE
    { col: 2, row: 3, color: rgba(191, 191, 191), label: 'pick' },    // IRON_PICKAXE
    { col: 3, row: 3, color: rgba(140, 90, 13), label: 'axe' },       // WOODEN_AXE
    { col: 4, row: 3, color: rgba(128, 128, 128), label: 'axe' },     // STONE_AXE
    { col: 5, row: 3, color: rgba(191, 191, 191), label: 'axe' },     // IRON_AXE
    { col: 6, row: 3, color: rgba(140, 90, 13), label: 'shovel' },    // WOODEN_SHOVEL
    { col: 7, row: 3, color: rgba(128, 128, 128), label: 'shovel' },  // STONE_SHOVEL
  ];

  for (const item of items) {
    const ox = item.col * cellSize;
    const oy = item.row * cellSize;

    if (item.color[3] === 0) continue; // skip transparent (NONE)

    // Draw a 12×12 centered item shape with 2px padding
    const pad = 2;
    const inner = cellSize - pad * 2;

    if (item.label === 'block') {
      // Filled square
      fillRect(pixels, width, ox + pad, oy + pad, inner, inner, item.color);
      // Dark border
      for (let i = pad; i < pad + inner; i++) {
        setPixel(pixels, width, ox + i, oy + pad, rgba(0, 0, 0, 80));
        setPixel(pixels, width, ox + i, oy + pad + inner - 1, rgba(0, 0, 0, 80));
        setPixel(pixels, width, ox + pad, oy + i, rgba(0, 0, 0, 80));
        setPixel(pixels, width, ox + pad + inner - 1, oy + i, rgba(0, 0, 0, 80));
      }
    } else if (item.label === 'gem') {
      // Diamond shape
      const cx = ox + 8, cy = oy + 8;
      for (let dy = -4; dy <= 4; dy++) {
        for (let dx = -(4 - Math.abs(dy)); dx <= (4 - Math.abs(dy)); dx++) {
          setPixel(pixels, width, cx + dx, cy + dy, item.color);
        }
      }
    } else if (item.label === 'ingot') {
      // Horizontal bar
      fillRect(pixels, width, ox + 3, oy + 5, 10, 6, item.color);
      // Highlight
      fillRect(pixels, width, ox + 4, oy + 6, 8, 2, rgba(255, 255, 255, 80));
    } else if (item.label === 'pick') {
      // Handle (diagonal line)
      for (let i = 0; i < 10; i++) {
        setPixel(pixels, width, ox + 3 + i, oy + 3 + i, rgba(100, 70, 30));
      }
      // Head
      fillRect(pixels, width, ox + 2, oy + 2, 8, 3, item.color);
    } else if (item.label === 'axe') {
      // Handle
      for (let i = 0; i < 10; i++) {
        setPixel(pixels, width, ox + 4 + i, oy + 4 + i, rgba(100, 70, 30));
      }
      // Head
      fillRect(pixels, width, ox + 2, oy + 2, 5, 6, item.color);
    } else if (item.label === 'shovel') {
      // Handle
      for (let i = 0; i < 8; i++) {
        setPixel(pixels, width, ox + 7, oy + 2 + i, rgba(100, 70, 30));
      }
      // Blade
      fillRect(pixels, width, ox + 5, oy + 10, 5, 4, item.color);
    } else if (item.label === 'gear') {
      // Simple gear/cog shape
      fillRect(pixels, width, ox + 5, oy + 3, 6, 10, item.color);
      fillRect(pixels, width, ox + 3, oy + 5, 10, 6, item.color);
      addCross(pixels, width, ox + 8, oy + 8, rgba(255, 200, 50));
    } else if (item.label === 'arrow') {
      // Arrow pointing right
      fillRect(pixels, width, ox + 3, oy + 6, 8, 4, item.color);
      // Arrow head
      setPixel(pixels, width, ox + 12, oy + 7, rgba(217, 217, 51));
      setPixel(pixels, width, ox + 12, oy + 8, rgba(217, 217, 51));
      setPixel(pixels, width, ox + 13, oy + 7, rgba(217, 217, 51));
      setPixel(pixels, width, ox + 13, oy + 8, rgba(217, 217, 51));
    }
  }

  return createPNG(width, height, pixels);
}

/**
 * Entity sprite: horizontal strip of N frames, each frameW×frameH
 */
function generateEntitySprite(frames, frameW, frameH, baseColor, name) {
  const width = frames * frameW;
  const height = frameH;
  const pixels = Buffer.alloc(width * height * 4);

  for (let f = 0; f < frames; f++) {
    const ox = f * frameW;
    // Fill with base color
    fillRect(pixels, width, ox, 0, frameW, frameH, baseColor);

    // Add a small animation indicator (moving dot)
    const dotX = ox + 2 + (f * 3) % (frameW - 4);
    const dotY = Math.floor(frameH / 2);
    setPixel(pixels, width, dotX, dotY, rgba(255, 255, 255, 200));
    setPixel(pixels, width, dotX + 1, dotY, rgba(255, 255, 255, 200));

    // Frame border for clarity
    for (let x = 0; x < frameW; x++) {
      setPixel(pixels, width, ox + x, 0, rgba(0, 0, 0, 60));
      setPixel(pixels, width, ox + x, frameH - 1, rgba(0, 0, 0, 60));
    }
    for (let y = 0; y < frameH; y++) {
      setPixel(pixels, width, ox, y, rgba(0, 0, 0, 60));
      setPixel(pixels, width, ox + frameW - 1, y, rgba(0, 0, 0, 60));
    }
  }

  return createPNG(width, height, pixels);
}

// ============================================================================
// Main
// ============================================================================

console.log('Generating placeholder sprites...');

// 1. Terrain atlas (replace existing)
const terrainPath = join(GAME_DIR, 'resources', 'tiles', 'terrain_atlas.png');
writeFileSync(terrainPath, generateTerrainAtlas());
console.log(`  ✓ ${terrainPath}`);

// 2. Item icon atlas
const itemIconPath = join(GAME_DIR, 'resources', 'icons', 'items', 'item_icon_atlas.png');
mkdirSync(join(GAME_DIR, 'resources', 'icons', 'items'), { recursive: true });
writeFileSync(itemIconPath, generateItemIconAtlas());
console.log(`  ✓ ${itemIconPath}`);

// 3. Entity sprites
const entityDir = join(GAME_DIR, 'resources', 'sprites', 'entities');
mkdirSync(entityDir, { recursive: true });

const entitySprites = [
  { name: 'conveyor.png', frames: 4, w: 16, h: 16, color: rgba(89, 89, 102) },
  { name: 'item_entity.png', frames: 1, w: 16, h: 16, color: rgba(128, 128, 128) },
];

// 3a. Miner body — 48×16 (3 tiles wide), static dark chassis
const minerBodyPixels = Buffer.alloc(48 * 16 * 4);
// Dark metal chassis base
fillRect(minerBodyPixels, 48, 0, 0, 48, 16, rgba(51, 51, 51));
// Treads along bottom
fillRect(minerBodyPixels, 48, 1, 12, 46, 3, rgba(35, 35, 35));
// Tread detail dots
for (let x = 3; x < 46; x += 4) {
  setPixel(minerBodyPixels, 48, x, 13, rgba(70, 70, 70));
}
// Body highlight stripe
fillRect(minerBodyPixels, 48, 2, 3, 44, 2, rgba(70, 70, 70));
// Drill housing at front (right side)
fillRect(minerBodyPixels, 48, 38, 2, 8, 10, rgba(80, 80, 80));
fillRect(minerBodyPixels, 48, 44, 4, 3, 6, rgba(100, 100, 100));
// Engine block detail at rear
fillRect(minerBodyPixels, 48, 2, 5, 8, 6, rgba(60, 60, 60));
addCross(minerBodyPixels, 48, 6, 8, rgba(255, 200, 50));
const minerBodyPath = join(entityDir, 'miner_body.png');
writeFileSync(minerBodyPath, createPNG(48, 16, minerBodyPixels));
console.log(`  ✓ ${minerBodyPath}`);

// 3b. Miner head sprite sheet — 4 frames × 16×16 for idle, 4 frames × 16×16 for mining
// Layout: 8 frames total in a horizontal strip (128×16)
// Frames 0-3: idle (subtle bob), Frames 4-7: mining (active movement)
const headFrames = 8;
const headW = 16, headH = 16;
const headPixels = Buffer.alloc(headFrames * headW * headH * 4);
const headTotalW = headFrames * headW;

for (let f = 0; f < headFrames; f++) {
  const ox = f * headW;
  const isMining = f >= 4;
  const baseHeadColor = isMining ? rgba(60, 60, 70) : rgba(55, 55, 65);

  // Head shape (rounded-ish rectangle)
  fillRect(headPixels, headTotalW, ox + 2, 2, 12, 12, baseHeadColor);
  // Visor/eye
  const eyeY = 5 + (isMining ? (f % 2) : 0); // mining: eye jitters
  fillRect(headPixels, headTotalW, ox + 4, eyeY, 8, 3, rgba(100, 200, 255));
  // Antenna
  const antennaX = ox + 7;
  const antennaTop = isMining ? 1 : (f % 2 === 0 ? 0 : 1); // idle: slight bob
  setPixel(headPixels, headTotalW, antennaX, antennaTop, rgba(255, 100, 100));
  setPixel(headPixels, headTotalW, antennaX, antennaTop + 1, rgba(200, 200, 200));
  // Mining sparks
  if (isMining) {
    const sparkX = ox + 10 + ((f - 4) * 2) % 5;
    const sparkY = 10 + ((f - 4) % 3);
    if (sparkX < ox + headW && sparkY < headH) {
      setPixel(headPixels, headTotalW, sparkX, sparkY, rgba(255, 230, 50));
    }
  }
}
const minerHeadPath = join(entityDir, 'miner_head.png');
writeFileSync(minerHeadPath, createPNG(headTotalW, headH, headPixels));
console.log(`  ✓ ${minerHeadPath}`);

for (const s of entitySprites) {
  const path = join(entityDir, s.name);
  writeFileSync(path, generateEntitySprite(s.frames, s.w, s.h, s.color, s.name));
  console.log(`  ✓ ${path}`);
}

console.log('\nDone! All placeholder sprites generated.');
