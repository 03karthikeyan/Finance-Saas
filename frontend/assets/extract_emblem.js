const fs = require('fs');
const zlib = require('zlib');

function extractBlueEmblem(inputPath, outputPath) {
  const buf = fs.readFileSync(inputPath);
  let pos = 8;
  let width = 0, height = 0, colorType = 0;
  const idatChunks = [];

  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos);
    const type = buf.toString('ascii', pos + 4, pos + 8);
    const data = buf.subarray(pos + 8, pos + 8 + len);
    if (type === 'IHDR') {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      colorType = data[9];
    } else if (type === 'IDAT') {
      idatChunks.push(data);
    }
    pos += 12 + len;
  }

  const compressed = Buffer.concat(idatChunks);
  const decompressed = zlib.inflateSync(compressed);
  const bpp = colorType === 6 ? 4 : (colorType === 2 ? 3 : 4);
  const uncompressedRowSize = 1 + width * bpp;

  const unflattened = Buffer.alloc(height * (1 + width * bpp));
  decompressed.copy(unflattened);

  const outputRows = Buffer.alloc(height * (1 + width * 4));

  for (let y = 0; y < height; y++) {
    const filterType = unflattened[y * uncompressedRowSize];
    outputRows[y * (1 + width * 4)] = 0;

    for (let x = 0; x < width; x++) {
      let r, g, b, a;
      const srcIdx = y * uncompressedRowSize + 1 + x * bpp;
      
      if (filterType === 0) {
        r = unflattened[srcIdx];
        g = unflattened[srcIdx + 1];
        b = unflattened[srcIdx + 2];
        a = bpp === 4 ? unflattened[srcIdx + 3] : 255;
      } else if (filterType === 1) {
        r = unflattened[srcIdx];
        g = unflattened[srcIdx + 1];
        b = unflattened[srcIdx + 2];
        a = bpp === 4 ? unflattened[srcIdx + 3] : 255;
        if (x > 0) {
          const prevIdx = srcIdx - bpp;
          r = (r + unflattened[prevIdx]) & 0xFF;
          g = (g + unflattened[prevIdx + 1]) & 0xFF;
          b = (b + unflattened[prevIdx + 2]) & 0xFF;
          if (bpp === 4) a = (a + unflattened[prevIdx + 3]) & 0xFF;
          unflattened[srcIdx] = r;
          unflattened[srcIdx + 1] = g;
          unflattened[srcIdx + 2] = b;
          if (bpp === 4) unflattened[srcIdx + 3] = a;
        }
      } else if (filterType === 2) {
        r = unflattened[srcIdx];
        g = unflattened[srcIdx + 1];
        b = unflattened[srcIdx + 2];
        a = bpp === 4 ? unflattened[srcIdx + 3] : 255;
        if (y > 0) {
          const upIdx = (y - 1) * uncompressedRowSize + 1 + x * bpp;
          r = (r + unflattened[upIdx]) & 0xFF;
          g = (g + unflattened[upIdx + 1]) & 0xFF;
          b = (b + unflattened[upIdx + 2]) & 0xFF;
          if (bpp === 4) a = (a + unflattened[upIdx + 3]) & 0xFF;
          unflattened[srcIdx] = r;
          unflattened[srcIdx + 1] = g;
          unflattened[srcIdx + 2] = b;
          if (bpp === 4) unflattened[srcIdx + 3] = a;
        }
      } else if (filterType === 3) {
        r = unflattened[srcIdx];
        g = unflattened[srcIdx + 1];
        b = unflattened[srcIdx + 2];
        a = bpp === 4 ? unflattened[srcIdx + 3] : 255;
        const leftR = x > 0 ? unflattened[srcIdx - bpp] : 0;
        const leftG = x > 0 ? unflattened[srcIdx - bpp + 1] : 0;
        const leftB = x > 0 ? unflattened[srcIdx - bpp + 2] : 0;
        const leftA = x > 0 && bpp === 4 ? unflattened[srcIdx - bpp + 3] : (bpp === 4 ? 0 : 255);
        const upR = y > 0 ? unflattened[(y - 1) * uncompressedRowSize + 1 + x * bpp] : 0;
        const upG = y > 0 ? unflattened[(y - 1) * uncompressedRowSize + 1 + x * bpp + 1] : 0;
        const upB = y > 0 ? unflattened[(y - 1) * uncompressedRowSize + 1 + x * bpp + 2] : 0;
        const upA = y > 0 && bpp === 4 ? unflattened[(y - 1) * uncompressedRowSize + 1 + x * bpp + 3] : (bpp === 4 ? 0 : 255);
        r = (r + Math.floor((leftR + upR) / 2)) & 0xFF;
        g = (g + Math.floor((leftG + upG) / 2)) & 0xFF;
        b = (b + Math.floor((leftB + upB) / 2)) & 0xFF;
        if (bpp === 4) a = (a + Math.floor((leftA + upA) / 2)) & 0xFF;
        unflattened[srcIdx] = r;
        unflattened[srcIdx + 1] = g;
        unflattened[srcIdx + 2] = b;
        if (bpp === 4) unflattened[srcIdx + 3] = a;
      } else if (filterType === 4) {
        r = unflattened[srcIdx];
        g = unflattened[srcIdx + 1];
        b = unflattened[srcIdx + 2];
        a = bpp === 4 ? unflattened[srcIdx + 3] : 255;
        function paeth(a, b, c) {
          const p = a + b - c;
          const pa = Math.abs(p - a);
          const pb = Math.abs(p - b);
          const pc = Math.abs(p - c);
          if (pa <= pb && pa <= pc) return a;
          if (pb <= pc) return b;
          return c;
        }
        const aR = x > 0 ? unflattened[srcIdx - bpp] : 0;
        const aG = x > 0 ? unflattened[srcIdx - bpp + 1] : 0;
        const aB = x > 0 ? unflattened[srcIdx - bpp + 2] : 0;
        const aA = x > 0 && bpp === 4 ? unflattened[srcIdx - bpp + 3] : 0;
        const bR = y > 0 ? unflattened[(y - 1) * uncompressedRowSize + 1 + x * bpp] : 0;
        const bG = y > 0 ? unflattened[(y - 1) * uncompressedRowSize + 1 + x * bpp + 1] : 0;
        const bB = y > 0 ? unflattened[(y - 1) * uncompressedRowSize + 1 + x * bpp + 2] : 0;
        const bA = y > 0 && bpp === 4 ? unflattened[(y - 1) * uncompressedRowSize + 1 + x * bpp + 3] : 0;
        const cR = (x > 0 && y > 0) ? unflattened[(y - 1) * uncompressedRowSize + 1 + (x - 1) * bpp] : 0;
        const cG = (x > 0 && y > 0) ? unflattened[(y - 1) * uncompressedRowSize + 1 + (x - 1) * bpp + 1] : 0;
        const cB = (x > 0 && y > 0) ? unflattened[(y - 1) * uncompressedRowSize + 1 + (x - 1) * bpp + 2] : 0;
        const cA = (x > 0 && y > 0 && bpp === 4) ? unflattened[(y - 1) * uncompressedRowSize + 1 + (x - 1) * bpp + 3] : 0;
        r = (r + paeth(aR, bR, cR)) & 0xFF;
        g = (g + paeth(aG, bG, cG)) & 0xFF;
        b = (b + paeth(aB, bB, cB)) & 0xFF;
        if (bpp === 4) a = (a + paeth(aA, bA, cA)) & 0xFF;
        unflattened[srcIdx] = r;
        unflattened[srcIdx + 1] = g;
        unflattened[srcIdx + 2] = b;
        if (bpp === 4) unflattened[srcIdx + 3] = a;
      }

      const dstIdx = y * (1 + width * 4) + 1 + x * 4;
      
      // Calculate color saturation and blue dominance
      const maxC = Math.max(r, g, b);
      const minC = Math.min(r, g, b);
      const delta = maxC - minC;
      
      // Check if it's the blue/cyan emblem
      // The emblem has high blue dominance: b > r + 15 or (b > 100 && b > g) or cyan (g > 120 && b > 140 && r < 100)
      const isBlue = (b > r + 20 && b > 60) || (b > 100 && g > r + 15 && r < 140) || (b > 150 && r < 130);
      const isWhiteOrGrayBg = (r > 200 && g > 200 && b > 200 && delta < 25) || (r > 220 && g > 220 && b > 220);

      if (isBlue && !isWhiteOrGrayBg) {
        outputRows[dstIdx] = r;
        outputRows[dstIdx + 1] = g;
        outputRows[dstIdx + 2] = b;
        outputRows[dstIdx + 3] = a;
      } else {
        // Anti-aliased border blend
        if (b > r + 5 && delta > 15 && !isWhiteOrGrayBg) {
          const alphaFactor = Math.min(1, (b - r) / 30);
          outputRows[dstIdx] = r;
          outputRows[dstIdx + 1] = g;
          outputRows[dstIdx + 2] = b;
          outputRows[dstIdx + 3] = Math.round(a * alphaFactor);
        } else {
          outputRows[dstIdx] = 0;
          outputRows[dstIdx + 1] = 0;
          outputRows[dstIdx + 2] = 0;
          outputRows[dstIdx + 3] = 0;
        }
      }
    }
  }

  const deflated = zlib.deflateSync(outputRows);

  function crc32(buf) {
    let crc = 0xFFFFFFFF;
    for (let i = 0; i < buf.length; i++) {
      crc ^= buf[i];
      for (let j = 0; j < 8; j++) {
        crc = (crc >>> 1) ^ (0xEDB88320 & -(crc & 1));
      }
    }
    return (crc ^ 0xFFFFFFFF) >>> 0;
  }

  function makeChunk(typeStr, dataBuf) {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(dataBuf.length, 0);
    const type = Buffer.from(typeStr, 'ascii');
    const crcBuf = Buffer.alloc(4);
    crcBuf.writeUInt32BE(crc32(Buffer.concat([type, dataBuf])), 0);
    return Buffer.concat([len, type, dataBuf, crcBuf]);
  }

  const ihdrData = Buffer.alloc(13);
  ihdrData.writeUInt32BE(width, 0);
  ihdrData.writeUInt32BE(height, 4);
  ihdrData[8] = 8;
  ihdrData[9] = 6;
  ihdrData[10] = 0;
  ihdrData[11] = 0;
  ihdrData[12] = 0;

  const pngSig = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  const ihdrChunk = makeChunk('IHDR', ihdrData);
  const idatChunk = makeChunk('IDAT', deflated);
  const iendChunk = makeChunk('IEND', Buffer.alloc(0));

  const resultPng = Buffer.concat([pngSig, ihdrChunk, idatChunk, iendChunk]);
  fs.writeFileSync(outputPath, resultPng);
  console.log(`Saved transparent emblem to ${outputPath} (${resultPng.length} bytes)`);
}

extractBlueEmblem('./assets/FMP_icon.png', './assets/fmp_emblem.png');
