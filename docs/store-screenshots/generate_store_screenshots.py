#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


OUT_ROOT = Path(__file__).resolve().parent


@dataclass(frozen=True)
class ExportSpec:
    platform: str
    width: int
    height: int
    phone_width: int
    phone_height: int


@dataclass(frozen=True)
class Shot:
    slug: str
    title: str
    subtitle: str
    tab: str
    screen: str


EXPORTS = (
    ExportSpec("ios", 1290, 2796, 930, 1810),
    ExportSpec("android", 1080, 1920, 760, 1340),
)

SHOTS = (
    Shot(
        "01-dashboard",
        "Widzisz, kto komu ile oddaje",
        "Saldo miesiaca bez stresu i bez arkuszy.",
        "Start",
        "dashboard",
    ),
    Shot(
        "02-add-expense",
        "Dodaj koszt w minute",
        "Kwota, kategoria, data i zalacznik w jednym miejscu.",
        "Dodaj",
        "add",
    ),
    Shot(
        "03-expenses",
        "Paragony i historia w jednym miejscu",
        "Lista kosztow pokazuje status, zalacznik i kontekst.",
        "Koszty",
        "expenses",
    ),
    Shot(
        "04-reports",
        "Spokojne rozliczenia rodzicow",
        "Raport miesieczny porzadkuje koszty dziecka.",
        "Raporty",
        "reports",
    ),
)

COLORS = {
    "primary": "#0F766E",
    "secondary": "#C76F3D",
    "tertiary": "#375E97",
    "success": "#2F855A",
    "warning": "#B7791F",
    "danger": "#B42318",
    "surface": "#FAFAF7",
    "surface_variant": "#E7ECE7",
    "text": "#172326",
    "muted": "#5B676A",
    "white": "#FFFFFF",
}


def esc(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def text(
    value: str,
    x: float,
    y: float,
    size: int,
    *,
    color: str = COLORS["text"],
    weight: int = 500,
    anchor: str = "start",
    opacity: float | None = None,
) -> str:
    opacity_attr = f' opacity="{opacity}"' if opacity is not None else ""
    return (
        f'<text x="{x:.1f}" y="{y:.1f}" fill="{color}" '
        f'font-family="Arial, Helvetica, sans-serif" '
        f'font-size="{size}" font-weight="{weight}" '
        f'text-anchor="{anchor}" letter-spacing="0"{opacity_attr}>{esc(value)}</text>'
    )


def rounded_rect(
    x: float,
    y: float,
    width: float,
    height: float,
    radius: float,
    fill: str,
    *,
    stroke: str | None = None,
    stroke_width: float = 1,
    opacity: float | None = None,
) -> str:
    stroke_attr = f' stroke="{stroke}" stroke-width="{stroke_width}"' if stroke else ""
    opacity_attr = f' opacity="{opacity}"' if opacity is not None else ""
    return (
        f'<rect x="{x:.1f}" y="{y:.1f}" width="{width:.1f}" height="{height:.1f}" '
        f'rx="{radius:.1f}" fill="{fill}"{stroke_attr}{opacity_attr}/>'
    )


def icon_mark(x: float, y: float, size: float) -> str:
    scale = size / 128
    return f"""
  <g transform="translate({x:.1f} {y:.1f}) scale({scale:.4f})">
    <rect x="12" y="12" width="104" height="104" rx="28" fill="{COLORS['primary']}"/>
    <path d="M39 34C39 30.686 41.686 28 45 28H83C86.314 28 89 30.686 89 34V94C89 97.314 86.314 100 83 100H45C41.686 100 39 97.314 39 94V34Z" fill="{COLORS['surface']}"/>
    <path d="M51 43H77" stroke="{COLORS['primary']}" stroke-width="6" stroke-linecap="round"/>
    <path d="M51 58H70" stroke="{COLORS['primary']}" stroke-width="6" stroke-linecap="round"/>
    <path d="M51 73H77" stroke="{COLORS['primary']}" stroke-width="6" stroke-linecap="round"/>
    <path d="M51 88H66" stroke="{COLORS['secondary']}" stroke-width="6" stroke-linecap="round"/>
    <path d="M45 30L78 64L45 98" stroke="{COLORS['primary']}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M78 64L91 51" stroke="{COLORS['secondary']}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
  </g>"""


def nav_icon(label: str, active: bool, x: float, y: float) -> str:
    color = COLORS["primary"] if active else "#879194"
    dot = rounded_rect(x + 25, y, 34, 8, 4, color, opacity=0.22 if active else 0)
    return (
        f"{dot}\n"
        f'  <circle cx="{x + 42:.1f}" cy="{y + 25:.1f}" r="13" fill="none" stroke="{color}" stroke-width="5"/>\n'
        f"{text(label, x + 42, y + 68, 20, color=color, weight=600 if active else 500, anchor='middle')}"
    )


def app_chrome(spec: ExportSpec, shot: Shot, body: str) -> str:
    phone_x = (spec.width - spec.phone_width) / 2
    phone_y = spec.height - spec.phone_height - max(120, spec.height * 0.055)
    top = phone_y + 42
    app_x = phone_x + 42
    app_w = spec.phone_width - 84
    nav_y = phone_y + spec.phone_height - 155
    nav_gap = app_w / 5

    return f"""
  {rounded_rect(phone_x, phone_y, spec.phone_width, spec.phone_height, 72, "#172326", opacity=0.10)}
  {rounded_rect(phone_x + 12, phone_y + 12, spec.phone_width - 24, spec.phone_height - 24, 64, COLORS['white'])}
  {rounded_rect(phone_x + 48, phone_y + 28, spec.phone_width - 96, 34, 17, "#172326", opacity=0.08)}
  {text(shot.tab, app_x, top + 70, 42, weight=700)}
  {body}
  <line x1="{app_x:.1f}" y1="{nav_y:.1f}" x2="{app_x + app_w:.1f}" y2="{nav_y:.1f}" stroke="{COLORS['surface_variant']}" stroke-width="3"/>
  <g>
    {nav_icon("Start", shot.tab == "Start", app_x + nav_gap * 0.0, nav_y + 26)}
    {nav_icon("Koszty", shot.tab == "Koszty", app_x + nav_gap * 1.0, nav_y + 26)}
    {nav_icon("Dodaj", shot.tab == "Dodaj", app_x + nav_gap * 2.0, nav_y + 26)}
    {nav_icon("Opieka", False, app_x + nav_gap * 3.0, nav_y + 26)}
    {nav_icon("Raporty", shot.tab == "Raporty", app_x + nav_gap * 4.0, nav_y + 26)}
  </g>"""


def card(x: float, y: float, w: float, h: float, title: str, body: str, amount: str | None = None) -> str:
    amount_text = text(amount, x + w - 26, y + 64, 30, color=COLORS["primary"], weight=700, anchor="end") if amount else ""
    return f"""
  {rounded_rect(x, y, w, h, 18, COLORS['white'], stroke=COLORS['surface_variant'], stroke_width=3)}
  {text(title, x + 26, y + 56, 26, weight=700)}
  {amount_text}
  {text(body, x + 26, y + 101, 22, color=COLORS['muted'])}"""


def dashboard_body(spec: ExportSpec) -> str:
    px = (spec.width - spec.phone_width) / 2 + 42
    py = spec.height - spec.phone_height - max(120, spec.height * 0.055) + 160
    w = spec.phone_width - 84
    return f"""
  {card(px, py, w, 170, "Saldo miesiaca", "Rodzic B oddaje Rodzicowi A", "86,50 zl")}
  {card(px, py + 200, w, 150, "Wydatki w tym miesiacu", "Dziecko - czerwiec 2026", "412,00 zl")}
  {rounded_rect(px, py + 390, w, 310, 18, "#F6FBFA", stroke=COLORS['surface_variant'], stroke_width=3)}
  {text("Ostatnie koszty", px + 26, py + 442, 28, weight=700)}
  {expense_row(px + 26, py + 480, w - 52, "Lekarze i leki", "2026-06-22", "120,00 zl", COLORS['danger'])}
  {expense_row(px + 26, py + 575, w - 52, "Obiad szkolny", "2026-06-20", "38,00 zl", COLORS['secondary'])}
  {expense_row(px + 26, py + 670, w - 52, "Basen", "2026-06-18", "54,00 zl", COLORS['tertiary'])}"""


def expense_row(x: float, y: float, w: float, title: str, date: str, amount: str, color: str) -> str:
    return f"""
  <circle cx="{x + 24:.1f}" cy="{y + 25:.1f}" r="20" fill="{color}" opacity="0.14"/>
  <circle cx="{x + 24:.1f}" cy="{y + 25:.1f}" r="9" fill="{color}"/>
  {text(title, x + 64, y + 18, 23, weight=700)}
  {text(date, x + 64, y + 52, 20, color=COLORS['muted'])}
  {text(amount, x + w, y + 33, 23, color=COLORS['text'], weight=700, anchor='end')}"""


def add_body(spec: ExportSpec) -> str:
    px = (spec.width - spec.phone_width) / 2 + 42
    py = spec.height - spec.phone_height - max(120, spec.height * 0.055) + 160
    w = spec.phone_width - 84
    chips = "".join(
        chip(px + (i % 2) * ((w - 24) / 2 + 24), py + 380 + (i // 2) * 78, (w - 24) / 2, label, active)
        for i, (label, active) in enumerate(
            [
                ("Jedzenie", False),
                ("Ubrania", False),
                ("Szkola", False),
                ("Lekarze", True),
                ("Zajecia", False),
                ("Transport", False),
            ]
        )
    )
    return f"""
  {input_box(px, py, w, "Kwota", "120,00 zl", COLORS['primary'])}
  {input_box(px, py + 120, w, "Data kosztu", "2026-06-22", COLORS['tertiary'])}
  {input_box(px, py + 240, w, "Dziecko", "Dziecko", COLORS['secondary'])}
  {text("Kategoria", px, py + 365, 24, color=COLORS['muted'], weight=600)}
  {chips}
  {input_box(px, py + 645, w, "Opis", "Wizyta kontrolna", COLORS['danger'])}
  {rounded_rect(px, py + 780, w, 82, 16, COLORS['white'], stroke=COLORS['surface_variant'], stroke_width=3)}
  {text("Dodaj paragon lub PDF", px + 28, py + 833, 25, color=COLORS['text'], weight=700)}
  {rounded_rect(px, py + 890, w, 88, 22, COLORS['primary'])}
  {text("Zapisz koszt", px + w / 2, py + 947, 27, color=COLORS['white'], weight=700, anchor='middle')}"""


def input_box(x: float, y: float, w: float, label: str, value: str, color: str) -> str:
    return f"""
  {rounded_rect(x, y, w, 96, 16, COLORS['white'], stroke=COLORS['surface_variant'], stroke_width=3)}
  <circle cx="{x + 34:.1f}" cy="{y + 48:.1f}" r="16" fill="{color}" opacity="0.18"/>
  {text(label, x + 68, y + 34, 19, color=COLORS['muted'], weight=600)}
  {text(value, x + 68, y + 68, 26, weight=700)}"""


def chip(x: float, y: float, w: float, label: str, active: bool) -> str:
    fill = "#E5F5F2" if active else COLORS["white"]
    stroke = COLORS["primary"] if active else COLORS["surface_variant"]
    color = COLORS["primary"] if active else COLORS["text"]
    return f"""
  {rounded_rect(x, y, w, 58, 29, fill, stroke=stroke, stroke_width=3)}
  {text(label, x + w / 2, y + 38, 22, color=color, weight=700, anchor='middle')}"""


def expenses_body(spec: ExportSpec) -> str:
    px = (spec.width - spec.phone_width) / 2 + 42
    py = spec.height - spec.phone_height - max(120, spec.height * 0.055) + 160
    w = spec.phone_width - 84
    return f"""
  {rounded_rect(px, py, w, 112, 18, COLORS['white'], stroke=COLORS['surface_variant'], stroke_width=3)}
  {text("Filtry", px + 26, py + 45, 26, weight=700)}
  {text("Czerwiec 2026  /  Wszystkie statusy", px + 26, py + 82, 22, color=COLORS['muted'])}
  {expense_card(px, py + 142, w, "Wizyta kontrolna", "Lekarze i leki - Dziecko - Rodzic A", "120,00 zl", "Do akceptacji", COLORS['warning'])}
  {expense_card(px, py + 342, w, "Obiad szkolny", "Jedzenie - Dziecko - Rodzic B", "38,00 zl", "Zaakceptowany", COLORS['success'])}
  {expense_card(px, py + 542, w, "Buty sportowe", "Ubrania - Dziecko - Rodzic A", "154,00 zl", "Wymaga wyjasnienia", COLORS['danger'])}
  {expense_card(px, py + 742, w, "Basen", "Zajecia - Dziecko - Rodzic B", "54,00 zl", "Rozliczony", COLORS['primary'])}"""


def expense_card(x: float, y: float, w: float, title: str, meta: str, amount: str, status: str, color: str) -> str:
    return f"""
  {rounded_rect(x, y, w, 172, 18, COLORS['white'], stroke=COLORS['surface_variant'], stroke_width=3)}
  <circle cx="{x + 36:.1f}" cy="{y + 48:.1f}" r="22" fill="{color}" opacity="0.18"/>
  {text(title, x + 76, y + 47, 25, weight=700)}
  {text(amount, x + w - 26, y + 48, 25, weight=700, anchor='end')}
  {text(meta, x + 76, y + 84, 19, color=COLORS['muted'])}
  {rounded_rect(x + 76, y + 108, 245, 44, 22, color, opacity=0.12)}
  {text(status, x + 100, y + 138, 19, color=color, weight=700)}"""


def reports_body(spec: ExportSpec) -> str:
    px = (spec.width - spec.phone_width) / 2 + 42
    py = spec.height - spec.phone_height - max(120, spec.height * 0.055) + 160
    w = spec.phone_width - 84
    bar_x = px + 52
    return f"""
  {card(px, py, w, 150, "Czerwiec 2026", "Koszty dziecka w tym miesiacu", "412,00 zl")}
  {rounded_rect(px, py + 190, w, 360, 18, COLORS['white'], stroke=COLORS['surface_variant'], stroke_width=3)}
  {text("Kategorie", px + 26, py + 244, 28, weight=700)}
  {bar(bar_x, py + 295, w - 104, 0.72, "Lekarze i leki", "120,00 zl", COLORS['danger'])}
  {bar(bar_x, py + 380, w - 104, 0.55, "Ubrania", "154,00 zl", "#7C5CBA")}
  {bar(bar_x, py + 465, w - 104, 0.38, "Jedzenie", "84,00 zl", COLORS['secondary'])}
  {rounded_rect(px, py + 590, w, 250, 18, "#F6FBFA", stroke=COLORS['surface_variant'], stroke_width=3)}
  {text("Eksport", px + 26, py + 648, 28, weight=700)}
  {text("CSV i PDF beda gotowe do spokojnej rozmowy", px + 26, py + 696, 22, color=COLORS['muted'])}
  {rounded_rect(px + 26, py + 738, 210, 56, 16, COLORS['primary'])}
  {text("Eksport CSV", px + 131, py + 775, 21, color=COLORS['white'], weight=700, anchor='middle')}"""


def bar(x: float, y: float, w: float, pct: float, label: str, amount: str, color: str) -> str:
    return f"""
  {text(label, x, y, 22, weight=700)}
  {text(amount, x + w, y, 22, color=COLORS['muted'], anchor='end')}
  {rounded_rect(x, y + 22, w, 20, 10, COLORS['surface_variant'])}
  {rounded_rect(x, y + 22, w * pct, 20, 10, color)}"""


def screen_body(spec: ExportSpec, shot: Shot) -> str:
    if shot.screen == "dashboard":
        return dashboard_body(spec)
    if shot.screen == "add":
        return add_body(spec)
    if shot.screen == "expenses":
        return expenses_body(spec)
    if shot.screen == "reports":
        return reports_body(spec)
    raise ValueError(shot.screen)


def svg_for(spec: ExportSpec, shot: Shot) -> str:
    top_y = 150 if spec.height > 2200 else 92
    mark_size = 96 if spec.height > 2200 else 70
    title_size = 58 if spec.height > 2200 else 42
    subtitle_size = 32 if spec.height > 2200 else 24
    body = app_chrome(spec, shot, screen_body(spec, shot))
    return f"""<svg width="{spec.width}" height="{spec.height}" viewBox="0 0 {spec.width} {spec.height}" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="{spec.width}" height="{spec.height}" fill="{COLORS['surface']}"/>
  <circle cx="{spec.width - 130}" cy="{top_y + 20}" r="{spec.width * 0.25:.1f}" fill="{COLORS['surface_variant']}" opacity="0.42"/>
  {icon_mark(96 if spec.width > 1100 else 70, top_y - 15, mark_size)}
  {text("KidCost", 96 + mark_size + 28 if spec.width > 1100 else 70 + mark_size + 22, top_y + 50, 40 if spec.width > 1100 else 31, weight=800)}
  {text(shot.title, spec.width / 2, top_y + 210, title_size, weight=800, anchor='middle')}
  {text(shot.subtitle, spec.width / 2, top_y + 275, subtitle_size, color=COLORS['muted'], anchor='middle')}
  {body}
</svg>
"""


def write_sources() -> list[tuple[ExportSpec, Shot, Path]]:
    outputs = []
    for spec in EXPORTS:
        source_dir = OUT_ROOT / "source" / spec.platform
        source_dir.mkdir(parents=True, exist_ok=True)
        for shot in SHOTS:
            path = source_dir / f"{shot.slug}.svg"
            svg = "\n".join(line.rstrip() for line in svg_for(spec, shot).splitlines()) + "\n"
            path.write_text(svg, encoding="utf-8")
            outputs.append((spec, shot, path))
    return outputs


def render_png(spec: ExportSpec, source: Path, dest: Path) -> None:
    sips = shutil.which("sips")
    if sips is None:
        return

    dest.parent.mkdir(parents=True, exist_ok=True)
    direct = subprocess.run(
        [sips, "-s", "format", "png", "-z", str(spec.height), str(spec.width), str(source), "--out", str(dest)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if direct.returncode == 0:
        return

    qlmanage = shutil.which("qlmanage")
    if qlmanage is None:
        return

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        subprocess.run(
            [qlmanage, "-t", "-s", str(max(spec.width, spec.height)), "-o", str(tmp_path), str(source)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        rendered = tmp_path / f"{source.name}.png"
        subprocess.run(
            [sips, "-z", str(spec.height), str(spec.width), str(rendered), "--out", str(dest)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def write_manifest() -> None:
    manifest = {
        "issue": 28,
        "demoData": ["Dziecko", "Rodzic A", "Rodzic B", "demo@kidcost.app"],
        "exports": [
            {
                "platform": spec.platform,
                "width": spec.width,
                "height": spec.height,
                "files": [f"{shot.slug}.png" for shot in SHOTS],
            }
            for spec in EXPORTS
        ],
        "copy": [shot.title for shot in SHOTS],
    }
    (OUT_ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    outputs = write_sources()
    for spec, shot, source in outputs:
        render_png(spec, source, OUT_ROOT / spec.platform / f"{shot.slug}.png")
    write_manifest()
    print(f"Generated {len(outputs)} SVG sources and store PNG exports in {OUT_ROOT}")


if __name__ == "__main__":
    main()
