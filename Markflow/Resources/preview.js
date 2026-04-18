(function() {
  // Swap highlight.js theme based on color scheme
  function applyHljsTheme() {
    const link = document.getElementById('hljs-theme');
    const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    link.href = dark ? 'highlight-github-dark.css' : 'highlight-github.css';
  }
  applyHljsTheme();
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', applyHljsTheme);

  // Mermaid is loaded on-demand only when a ```mermaid block is present.
  let mermaidLoader = null;
  function ensureMermaid() {
    if (window.mermaid) return Promise.resolve();
    if (mermaidLoader) return mermaidLoader;
    mermaidLoader = new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = 'mermaid.min.js';
      s.async = true;
      s.onload = () => {
        try {
          window.mermaid.initialize({
            startOnLoad: false,
            theme: window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default',
            securityLevel: 'loose',
            flowchart: { htmlLabels: true, curve: 'basis' }
          });
        } catch (e) { console.error('mermaid init failed:', e); }
        resolve();
      };
      s.onerror = () => {
        mermaidLoader = null;
        reject(new Error('mermaid.min.js failed to load'));
      };
      document.head.appendChild(s);
    });
    return mermaidLoader;
  }

  // Custom marked renderer — emit mermaid blocks as <pre class="mermaid">
  // so mermaid's run() picks them up, and skip hljs for them.
  const renderer = new marked.Renderer();
  const defaultCode = renderer.code.bind(renderer);
  renderer.code = function(code, lang, escaped) {
    // marked v15 passes a token object; normalize
    let text, language;
    if (typeof code === 'object' && code !== null) {
      text = code.text;
      language = code.lang;
    } else {
      text = code;
      language = lang;
    }
    if (language === 'mermaid') {
      // Mermaid needs the raw source in the element
      return '<pre class="mermaid">' + escapeHtml(text) + '</pre>\n';
    }
    // Let marked handle non-mermaid code; hljs highlights it after innerHTML
    return defaultCode(code, lang, escaped);
  };

  function escapeHtml(s) {
    return s
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  marked.use({ renderer, breaks: true, gfm: true });

  // Expose render() for Swift to call via evaluateJavaScript
  let mermaidCounter = 0;
  window.render = async function(md) {
    const el = document.getElementById('content');
    if (!md || md.length === 0) {
      el.innerHTML = '<div id="empty">Nothing here yet — tap Edit to start.</div>';
      return;
    }
    try {
      el.innerHTML = marked.parse(md);

      // Syntax highlight any language-* code blocks (skip mermaid)
      el.querySelectorAll('pre code[class*="language-"]').forEach((block) => {
        try { hljs.highlightElement(block); } catch (e) {}
      });

      // Render mermaid diagrams — lazy-load the library on first use
      const mermaidBlocks = el.querySelectorAll('pre.mermaid');
      if (mermaidBlocks.length > 0) {
        try {
          await ensureMermaid();
          mermaidBlocks.forEach((b) => {
            b.id = 'mermaid-' + (++mermaidCounter);
          });
          await window.mermaid.run({ nodes: mermaidBlocks });
        } catch (e) {
          console.error('mermaid error:', e);
        }
      }
    } catch (e) {
      el.innerText = String(e);
    }
  };
})();
