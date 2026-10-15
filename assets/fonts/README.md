# Lightning Wordmark

`LightningWordmark.ttf` is a modified Roboto Medium from the Flutter SDK's
`bin/cache/artifacts/material_fonts/Roboto-Medium.ttf`. Original Roboto glyphs
and hinting are retained. The added U+E000 glyph is a small-size lightning i,
with its own advance width, side bearings and TrueType grid-fitting instructions.
The normal lowercase i is preserved for the second i in “Lightning”.

The font family and PostScript names are changed to Lightning Wordmark. The
original Apache 2.0 license is included in `Roboto_LICENSE.txt` and bundled with
the app. This font is used only for the wordmark, not for ordinary interface text.

Rebuild from the original static, 2048-unit Roboto Medium font with Python 3:

```sh
python3 tools/build_wordmark_font.py /path/to/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf
```

The generator uses Python's standard library and checks the resulting font
checksum, cmap mapping, glyph count and horizontal-metrics length. It preserves
all original glyph indices so existing shaping/hinting tables remain valid.
