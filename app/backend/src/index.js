import express from "express";
import cors from "cors";
import { pool, initSchema } from "./db.js";
import { postsRouter } from "./routes/posts.js";
import { register, metricsMiddleware } from "./metrics.js";

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(metricsMiddleware);

// Liveness/readiness — wired to k8s probes in gitops/base/backend-deployment.yaml
app.get("/api/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "ok" });
  } catch (err) {
    res.status(503).json({ status: "db_unreachable", error: err.message });
  }
});

// Scraped by Prometheus — see observability/prometheus/alert-rules.yaml
app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.use("/api/posts", postsRouter);

app.listen(PORT, async () => {
  await initSchema();
  console.log(`signalboard-backend listening on :${PORT}`);
});
