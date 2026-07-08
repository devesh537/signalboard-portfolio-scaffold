import { useEffect, useState } from "react";

export default function App() {
  const [posts, setPosts] = useState([]);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [health, setHealth] = useState("checking...");

  async function loadPosts() {
    const res = await fetch("/api/posts");
    setPosts(await res.json());
  }

  async function checkHealth() {
    try {
      const res = await fetch("/api/health");
      const data = await res.json();
      setHealth(data.status);
    } catch {
      setHealth("unreachable");
    }
  }

  useEffect(() => {
    loadPosts();
    checkHealth();
  }, []);

  async function createPost(e) {
    e.preventDefault();
    if (!title || !body) return;
    await fetch("/api/posts", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, body }),
    });
    setTitle("");
    setBody("");
    loadPosts();
  }

  return (
    <div style={{ maxWidth: 640, margin: "40px auto", fontFamily: "sans-serif" }}>
      <h1>Signalboard</h1>
      <p>backend health: <strong>{health}</strong></p>

      <form onSubmit={createPost} style={{ marginBottom: 24 }}>
        <input
          placeholder="Title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          style={{ display: "block", width: "100%", marginBottom: 8, padding: 8 }}
        />
        <textarea
          placeholder="Body"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          style={{ display: "block", width: "100%", marginBottom: 8, padding: 8 }}
        />
        <button type="submit">Create post</button>
      </form>

      {posts.map((p) => (
        <div key={p.id} style={{ borderBottom: "1px solid #ddd", padding: "12px 0" }}>
          <h3>{p.title}</h3>
          <p>{p.body}</p>
        </div>
      ))}
    </div>
  );
}
