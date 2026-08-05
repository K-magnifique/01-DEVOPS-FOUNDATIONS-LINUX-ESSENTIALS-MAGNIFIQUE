const http = require("http");

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok" }));
    return;
  }

  if (req.url.startsWith("/api/orders")) {
    if (!process.env.DB_HOST) {
      res.writeHead(503, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "database unavailable" }));
      return;
    }
    const url = new URL(req.url, `http://${req.headers.host}`);
    const status = url.searchParams.get("status");
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ orders: [], status: status || null }));
    return;
  }

  res.writeHead(404, { "Content-Type": "text/plain" });
  res.end("Not Found");
});

server.listen(PORT, () => {
  console.log(`Kente Retail order-service listening on port ${PORT}`);
});

server.listen(PORT, () => {
  console.log(`Kente Retail order-service listening on port ${PORT}`);
});
