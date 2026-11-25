// 极简静态文件服务器：node server.mjs [端口]，仅用于本地预览 architecture/dsh 目录
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('.', import.meta.url));
const port = Number(process.argv[2]) || 8766;
const types = {
  '.html': 'text/html; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.md': 'text/markdown; charset=utf-8',
};

createServer(async (req, res) => {
  try {
    // 防目录穿越：规范化路径并限制在 root 内
    let urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (urlPath.endsWith('/')) urlPath += 'index.html';
    const file = normalize(join(root, urlPath));
    if (!file.startsWith(root)) { res.writeHead(403); return res.end('Forbidden'); }
    const data = await readFile(file);
    res.writeHead(200, { 'Content-Type': types[extname(file)] || 'application/octet-stream' });
    res.end(data);
  } catch {
    res.writeHead(404); res.end('Not Found');
  }
}).listen(port, '127.0.0.1', () => console.log(`Preview: http://127.0.0.1:${port}/index.html`));
