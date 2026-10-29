"""Extrae el codigo VBScript de las paginas ASP clasicas y lo compila con cscript.

Sirve para detectar errores de sintaxis (Dim duplicado, If sin End If, etc.)
sin necesidad de un servidor IIS.
"""
import os, re, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCLUDE_RE = re.compile(r'<!--#include\s+file="([^"]+)"\s*-->', re.IGNORECASE)
BLOCK_RE = re.compile(r'<%(.*?)%>', re.DOTALL)


def resolve_includes(path, seen=None, depth=0):
    """Devuelve el texto con los includes expandidos, preservando lineas."""
    if seen is None:
        seen = set()
    key = os.path.normcase(os.path.abspath(path))
    if key in seen or depth > 12:
        return ''
    seen.add(key)

    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        text = f.read()

    out = []
    pos = 0
    for m in INCLUDE_RE.finditer(text):
        out.append(text[pos:m.start()])
        inc = os.path.join(os.path.dirname(path), m.group(1))
        if os.path.exists(inc):
            out.append(resolve_includes(inc, seen, depth + 1))
        else:
            out.append('')
        pos = m.end()
    out.append(text[pos:])
    return ''.join(out)


def to_vbs(text):
    """Convierte el contenido ASP en un script VBScript valido."""
    lines = []
    pos = 0
    for m in BLOCK_RE.finditer(text):
        # texto HTML -> lineas vacias (mantiene numeracion)
        chunk = text[pos:m.start()]
        lines.append('\n' * chunk.count('\n'))
        pos = m.end()

        body = m.group(1)
        if body.startswith('@'):
            # directiva <%@ ... %>
            lines.append('\n' * body.count('\n'))
            continue

        stripped = body.lstrip()
        if stripped.startswith('='):
            expr = stripped[1:].strip()
            lines.append('Response.Write (' + expr + ')\n')
        else:
            lines.append(body + '\n')
    lines.append('\n' * text[pos:].count('\n'))
    return ''.join(lines)


def check(page):
    src = resolve_includes(page)
    vbs = to_vbs(src)
    tmp = os.path.join(tempfile.gettempdir(), 'pm_check.vbs')
    with open(tmp, 'w', encoding='utf-16-le') as f:
        f.write('\ufeff' + vbs)

    r = subprocess.run(['cscript', '//nologo', '//E:vbscript', tmp],
                       capture_output=True, text=True, errors='replace')
    out = (r.stdout or '') + (r.stderr or '')
    compile_err = 'compilation error' in out.lower() or 'error de compilaci' in out.lower()
    return compile_err, out, tmp


def main():
    pages = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames
                       if d not in ('tools', 'SongFilesAndImages_resources', '.workbuddy-ai',
                                    'Assets', 'albumImages', 'ArtistImages', 'playlistImages',
                                    'songFiles', 'userImages', 'inc')]
        for fn in filenames:
            if fn.lower().endswith('.asp'):
                pages.append(os.path.join(dirpath, fn))

    pages.sort()
    bad = 0
    for p in pages:
        err, out, tmp = check(p)
        rel = os.path.relpath(p, ROOT)
        if err:
            bad += 1
            print('=' * 70)
            print('COMPILE ERROR ->', rel)
            for line in out.splitlines()[:12]:
                print('   ', line)
        else:
            print('ok  ', rel)
    print()
    print(f'{len(pages)} paginas revisadas, {bad} con errores de compilacion')


if __name__ == '__main__':
    main()
