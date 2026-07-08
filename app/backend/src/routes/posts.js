import { Router } from "express";
import { pool } from "../db.js";

export const postsRouter = Router();

postsRouter.get("/", async (_req, res) => {
  const { rows } = await pool.query(
    "SELECT id, title, body, created_at FROM posts ORDER BY created_at DESC"
  );
  res.json(rows);
});

postsRouter.get("/:id", async (req, res) => {
  const { rows } = await pool.query("SELECT * FROM posts WHERE id = $1", [
    req.params.id,
  ]);
  if (rows.length === 0) return res.status(404).json({ error: "not found" });
  res.json(rows[0]);
});

postsRouter.post("/", async (req, res) => {
  const { title, body } = req.body;
  if (!title || !body) {
    return res.status(400).json({ error: "title and body are required" });
  }
  const { rows } = await pool.query(
    "INSERT INTO posts (title, body) VALUES ($1, $2) RETURNING *",
    [title, body]
  );
  res.status(201).json(rows[0]);
});

postsRouter.delete("/:id", async (req, res) => {
  await pool.query("DELETE FROM posts WHERE id = $1", [req.params.id]);
  res.status(204).send();
});
