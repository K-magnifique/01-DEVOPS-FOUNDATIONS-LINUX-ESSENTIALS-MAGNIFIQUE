const http = require("http");

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok" }));
    return;
  }

  if (req.url.startsWith("/api/orders")) {
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
