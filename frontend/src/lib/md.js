// md.js — a tiny, dependency-free Markdown renderer for the read views.
// Content comes from your own vault files (trusted), but we escape HTML first,
// so a stray `<` or `&` can never inject markup. Handles the handful of things
// our notes actually use: headings, bold/italic, inline + fenced code, lists,
// blockquotes, links, and [[wikilinks]].

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function inline(s) {
  s = esc(s);
  s = s.replace(/`([^`]+)`/g, (_, c) => `<code>${c}</code>`);                                  // inline code
  s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_, t, u) => `<a href="${u}" target="_blank" rel="noopener">${t}</a>`); // links
  s = s.replace(/\[\[([^\]]+)\]\]/g, (_, p) => p.split('|').pop().split('/').pop());            // wikilinks → words
  s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');                                     // bold
  s = s.replace(/(^|[^*])\*([^*\s][^*]*)\*/g, '$1<em>$2</em>');                                 // italic *x*
  s = s.replace(/(^|[^\w])_([^_]+)_/g, '$1<em>$2</em>');                                        // italic _x_
  return s;
}

export function renderMarkdown(md) {
  const lines = (md || '').split('\n');
  const out = [];
  let para = [];
  const flush = () => { if (para.length) { out.push(`<p>${inline(para.join(' '))}</p>`); para = []; } };
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (/^```/.test(line)) {                       // fenced code block
      flush();
      const buf = [];
      i++;
      while (i < lines.length && !/^```/.test(lines[i])) { buf.push(esc(lines[i])); i++; }
      i++;
      out.push(`<pre><code>${buf.join('\n')}</code></pre>`);
      continue;
    }
    const h = line.match(/^(#{2,4})\s+(.*)$/);     // headings (## and deeper; # is the title)
    if (h) { flush(); const l = h[1].length; out.push(`<h${l}>${inline(h[2])}</h${l}>`); i++; continue; }
    if (/^>\s?/.test(line)) {                       // blockquote
      flush();
      const buf = [];
      while (i < lines.length && /^>\s?/.test(lines[i])) { buf.push(inline(lines[i].replace(/^>\s?/, ''))); i++; }
      out.push(`<blockquote>${buf.join('<br>')}</blockquote>`);
      continue;
    }
    // lists — items may wrap onto indented continuation lines
    const gatherList = (itemRe) => {
      const items = [];
      while (i < lines.length) {
        const m = lines[i].match(itemRe);
        if (m) { items.push(m[1]); i++; }
        else if (items.length && /^\s+\S/.test(lines[i])) { items[items.length - 1] += ' ' + lines[i].trim(); i++; } // continuation
        else break;
      }
      return items.map((t) => `<li>${inline(t)}</li>`).join('');
    };
    if (/^[-*]\s+/.test(line)) { flush(); out.push(`<ul>${gatherList(/^[-*]\s+(.*)$/)}</ul>`); continue; }
    if (/^\d+\.\s+/.test(line)) { flush(); out.push(`<ol>${gatherList(/^\d+\.\s+(.*)$/)}</ol>`); continue; }
    if (/^\s*$/.test(line)) { flush(); i++; continue; }  // blank → paragraph break
    para.push(line.trim());
    i++;
  }
  flush();
  return out.join('\n');
}
