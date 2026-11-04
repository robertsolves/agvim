#!/bin/zsh
# The website's search and answer-engine basics, so they can't quietly regress. Claims
# about what AgVim does are checked by hand against the code when the copy changes.
docs="${0:A:h:h}/docs"
python3 -I - "$docs" <<'PY'
import html, json, os, re, sys
d = sys.argv[1]
s = open(d + "/index.html").read()
m = lambda p: (re.search(p, s) or [None, ""])[1]
title, desc = m(r"<title>(.*?)</title>"), m(r'name="description" content="(.*?)"')
print("title:", len(title)); print("description:", len(desc))
print("canonical = og:url:", "yes" if m(r'rel="canonical" href="(.*?)"') == m(r'og:url" content="(.*?)"') != "" else "no")
data = json.loads(m(r'(?s)ld\+json">\s*(.*?)\s*</script>'))
print("structured data: valid")
page = html.unescape(re.sub(r"<[^>]+>", " ", s.split("</head>")[1]))
page = re.sub(r"\s+", " ", page)
faq = [g for g in data["@graph"] if g["@type"] == "FAQPage"][0]["mainEntity"]
ok = all(q["name"] in page and q["acceptedAnswer"]["text"] in page for q in faq)
print("every FAQ answer is on the page:", "yes" if ok else "no")
print("sitemap lists the page:", "yes" if m(r'canonical" href="(.*?)"') in open(d + "/sitemap.xml").read() else "no")
print("files exist:", "yes" if all(os.path.exists(d + "/" + f) for f in ("icon.svg", "og.png", "llms.txt", "sitemap.xml")) else "no")
print("side by side:", page.lower().count("side by side") - 0)
PY
